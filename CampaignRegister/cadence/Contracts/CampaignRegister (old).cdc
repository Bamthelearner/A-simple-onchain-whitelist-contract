pub contract CampaignRegister {
    // Stores the public path of public capability and storage path
    pub let CampaignRegisterPublicPath : PublicPath
    pub let CampaignRegisterStoragePath : StoragePath

    init () {
        self.CampaignRegisterPublicPath = /public/campaignregistercollection
        self.CampaignRegisterStoragePath = /storage/campaignregistercollection
    }

    //Emit event when a campaign is created
    pub event CampaignAdded (by : Address? , CampaignName : String)
    //Emit event when a campaign is removed
    pub event CampaignRemoved (by : Address? , CampaignName : String)

    //Resource interface of campaign, disclose the function to the public
    pub resource interface CampaignPublic {

        pub let CampaignName : String

        pub fun getAddress () : [Address]
        pub fun registerAddress (acct : AuthAccount)
        pub fun getCampaignStatus() : Bool
        pub fun getCampaignCap () : UInt64

    } 

    //Campaign resource stores all the function , information and register addresses.
    pub resource Campaign : CampaignPublic{
        //CampaignName acts as a unique key to map to the campaign resources in campaign collection
        pub let CampaignName : String

        //Addresslist stores all the address registered to the campaign in a dictionary
        access(contract) var Addresslist : {Address : Bool}

        //Active regulates the address registration status, false will disable registration function
        pub var Active : Bool
        //StartTime and EndTime of a campaign regulated the registration status, registration function is disabled outside the time
        pub var StartTime : UFix64
        pub var EndTime: UFix64

        //CampaignCap is the maximum intake of this campaign, the registration stops after the cap is reached.
        pub var CampaignCap : UInt64

        init (_CampaignName : String, 
              _StartTime : UFix64,
              _EndTime : UFix64,
              _CampaignCap : UInt64) {

        self.CampaignName =  _CampaignName
        self.Addresslist = {}
        self.Active = true
        self.StartTime = _StartTime
        self.EndTime = _EndTime
        self.CampaignCap = _CampaignCap

        }

        //getAddress returns a list of registered addresses in array
        pub fun getAddress () : [Address]{
            return self.Addresslist.keys
        }

        //getCampaignCap returns the cap of the campaign registration
        pub fun getCampaignCap () : UInt64 {
            return self.CampaignCap
        }

        //checkTime returns true / false on whether the campaign registration is within the time
        pub fun checkTime () : Bool {
            let currentTime = getCurrentBlock().timestamp
            return self.StartTime < currentTime && currentTime < self.EndTime
        }

        //registerAddress register the signer's address to the Addresslist based on the campaigntime, status and the cap
        pub fun registerAddress (acct : AuthAccount) {
            let address = acct.address

            //case 1 : no cap for this campaign
            if self.CampaignCap == 0 {
                if self.Active && self.checkTime() {
                    self.Addresslist[address] = true
                }
                //case 2 : There is cap for this campaign
            }else if UInt64(self.Addresslist.keys.length) < self.CampaignCap {
                if self.Active && self.checkTime() {
                    self.Addresslist[address] = true
                }
            }
        }

        //getCampaignStatus returns whether the campaign is active
        pub fun getCampaignStatus() : Bool {
            return self.Active
        }

        //Admin Function
        //toggleCampaignStatus takes in a Bool to change the status of the campaign
        pub fun toggleCampaignStatus(Status : Bool) {
            self.Active = Status
        }

        //Admin Function --> only callable when the campaign registration is not active
        //changeCampaignTime takes in Start and End Time to change the campaign time
        pub fun changeCampaignTime(Start : UFix64, End : UFix64) {
            if !self.Active {
                self.StartTime = Start
                self.EndTime = End
            }
        }

        //Admin Function --> only callable when the campaign registration is not active
        //changeCampaignCap changes the campaign capacity
        pub fun changeCampaignCap(newCap : UInt64) {
            if !self.Active {
                self.CampaignCap = newCap
            }
        }

        //Admin Function --> only callable when the campaign registration is not active
        //removeAddress remove an address from the list
        pub fun removeAddress (address : Address) {
            if !self.Active {
                self.Addresslist.remove(key: address) ??panic ("Cannot find this address from the registry")
            }
        }
        

    }

    //Create a new campaign and deposit to the collection, using CampaignName as the key
    pub fun createCampaign(to: &CampaignCollection ,CampaignName : String, StartTime : UFix64, EndTime : UFix64, CampaignCap : UInt64) {
        let newcampaign <- create Campaign(_CampaignName : CampaignName, _StartTime : StartTime, _EndTime : EndTime, _CampaignCap : CampaignCap)
        emit CampaignAdded(by : newcampaign.owner?.address, CampaignName : newcampaign.CampaignName)
        to.deposit(campaign : <- newcampaign)
    }

    //Resource interface of CampaignCollection, disclose the function to the public
    pub resource interface CampaignCollectionPublic {

        pub fun borrowCampaignsPublic(CampaignName : String) : &Campaign{CampaignPublic}
        pub fun getCampaigns() : {String : Bool}
        
    }

    //Resource CampaignCollection stores campaigns using Campaign Name as key
    pub resource CampaignCollection : CampaignCollectionPublic {

        //using Campaign Name as key
        access(contract) var ownedCampaigns : @{String : Campaign}

        init(){
            self.ownedCampaigns <- {}
        }

        destroy () { 
            destroy self.ownedCampaigns
        }

        //Deposit stores the campaign resource to the collection
        pub fun deposit (campaign : @Campaign) {
            let campaignname : String = campaign.CampaignName
            self.ownedCampaigns[campaignname] <-! campaign

        }

        //Remove campaign takes out the campaign resource and returns it (Should be destroyed or handled in the trxn for safety)
        pub fun removeCampaign (campaignname : String) : @Campaign{
            let campaign <- self.ownedCampaigns.remove(key: campaignname) ?? panic("Cannot find this campaign from collection")
            emit CampaignRemoved(by : campaign.owner?.address, CampaignName : campaign.CampaignName)
            return <- campaign
        }

        //returns campaigns public reference, everyone can call this
        pub fun borrowCampaignsPublic(CampaignName : String) : &Campaign{CampaignPublic} {
            return &self.ownedCampaigns[CampaignName] as &Campaign{CampaignPublic}
        }

        //returns campaigns all reference, only the owner can call this
        pub fun borrowCampaigns(CampaignName : String) : &Campaign {
            return &self.ownedCampaigns[CampaignName] as &Campaign
        }

        //returns a {Campaign Name : Active Status } Map 
        pub fun getCampaigns() : {String : Bool} {
            let campaigns = self.ownedCampaigns.keys
            var maps : {String : Bool} = {}
            for campaign in campaigns {
                maps[campaign] = self.borrowCampaignsPublic(CampaignName : campaign).getCampaignStatus() 
            }
            return maps 
        }
    }

    //Create New Campaign Collection
    pub fun createCampaignCollection() : @CampaignCollection {
        return <- create CampaignCollection()
    }

}