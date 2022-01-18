pub contract CampaignRegister {

    /* 
    
    Storage Path Section

    */


    pub let CampaignRegisterPublicPath : PublicPath
    pub let CampaignRegisterPrivatePath : PrivatePath
    pub let CampaignRegisterStoragePath : StoragePath


    init () {
        self.CampaignRegisterPublicPath = /public/campaignregistercollection
        self.CampaignRegisterPrivatePath = /private/campaignregistercollection
        self.CampaignRegisterStoragePath = /storage/campaignregistercollection


    }



    /* 

    Event Definition Section

    */



    /*

    Resource Interface Section

    */

    // Resource Interface for "Campaign" to Public
    pub resource interface CampaignPublic {

        pub let CampaignName : String
        pub fun getAddress () : [Address]
        pub fun registerAddress (acct : AuthAccount)
        pub fun getCampaignStatus() : Bool
        pub fun getCampaignCap () : UInt64?
        pub fun getCampaignTime() : [UFix64?]
    } 

    // Resource Interface for "Campaign" to Private (for adding addresses on behalf of others)
    pub resource interface CampaignProxyPrivate {
        pub let CampaignName : String
        pub fun proxyregisterAddress(addrlist : [Address]) : [Address] 
        pub fun checkDistributedCapability(addr : Address) : Bool
    }


    //Resource interface for "CampaignCollection" to public
    pub resource interface CampaignCollectionPublic {

        pub fun borrowCampaignsPublic(campaignname : String) : &Campaign{CampaignPublic}
        pub fun getCampaigns() : {String : Bool}
        pub fun getCampaignCapslist() : {Address : [String]} 

        pub fun getCampaignCollectionCapabilityRef(addr : Address) : &CampaignCollectionCapability 
        access(contract) fun depositcapability(campaignaddr : Address, campaigncap : @CampaignCollectionCapability) 
        pub fun addcampaigntocap (campaignaddr : Address, campaignname : String) 
    }



    /*

    Resource Campaign Section

    */

    //Campaign resource stores 2 major things
    // 1. Addresses registered to the campaign, and functions around it
    // 2. To offer ability to specific addresses for signing addresses on behalf of others and functions around it
    pub resource Campaign : CampaignPublic, CampaignProxyPrivate{

        //CampaignName acts as a unique key to map to the campaign resources in campaign collection
        pub let CampaignName : String

        //Addresslist stores all the address registered to the campaign in a dictionary
        access(contract) var Addresslist : {Address : Bool}
        pub var Active : Bool
        pub var StartTime : UFix64?
        pub var EndTime: UFix64?
        pub var CampaignCap : UInt64?

        //DistributedCapability stores all the address that granted ability to bulk register
        access(contract) var DistributedCapability : {Address : Bool}

        init (_CampaignName : String, 
              _StartTime : UFix64?,
              _EndTime : UFix64?,
              _CampaignCap : UInt64?) {

        self.CampaignName =  _CampaignName
        self.Addresslist = {}
        self.Active = true
        self.StartTime = _StartTime
        self.EndTime = _EndTime
        self.CampaignCap = _CampaignCap
        self.DistributedCapability = {}
        }

        /* Function for Campaign Information */

        //getAddress returns a list of registered addresses in array
        pub fun getAddress () : [Address]{
            return self.Addresslist.keys
        }

        //getCampaignStatus returns whether the campaign is active
        pub fun getCampaignStatus() : Bool {
            return self.Active
        }

        //getCampaignTime returns the campaign start and end time
        pub fun getCampaignTime() : [UFix64?]{
            return [self.StartTime, self.EndTime]
        }

        //getCampaignCap returns the cap of the campaign registration
        pub fun getCampaignCap () : UInt64? {
            return self.CampaignCap
        }

        //getCampaignRemainCap returns the remaining seats for the campaign
        pub fun getCampaignRemainCap () : UInt64? {
            if let cap = self.CampaignCap {
                return cap - UInt64(self.Addresslist.length )
            } else {
                return nil
            }
        }

        /* Function for Campaign Management */
        /* Apart from toggleCampaignStatus, all functions need to be called in Active == false */

        //toggleCampaignStatus takes in a Bool to change the status of the campaign
        pub fun toggleCampaignStatus(Status : Bool) {
            self.Active = Status
        }

        //changeCampaignTime takes in Start and End Time to change the campaign time
        pub fun changeCampaignTime(Start : UFix64, End : UFix64) {
            pre {
                self.Active == false : "Admin Function has to be performed after deactivate the campaign registration"
            }

            self.StartTime = Start
            self.EndTime = End
            
        }

        //Admin Function --> only callable when the campaign registration is not active
        //changeCampaignCap changes the campaign capacity
        pub fun changeCampaignCap(newCap : UInt64) {
            pre {
                self.Active == false : "Admin Function has to be performed after deactivate the campaign registration"
            }

            self.CampaignCap = newCap
            
        }

        //removeAddress remove an address from the list
        pub fun removeAddress (addr : Address) {
            pre {
                self.Active == false : "Admin Function has to be performed after deactivate the campaign registration"
            }

            self.Addresslist.remove(key: addr) ??panic ("Cannot find this address from the registry")
            
        }


        /* Function for Campaign Register (Participants Registering themselves) */

        //checkTime returns true / false on whether the campaign registration is within the time and is used internally
        pub fun checkTime () : Bool {
                let currentTime = getCurrentBlock().timestamp

                let AfterStartTime = self.StartTime == nil || self.StartTime! < currentTime ? true : false
                let BeforeEndTime = self.EndTime == nil || self.EndTime! > currentTime ? true : false

                return AfterStartTime && BeforeEndTime
        }

        //registerAddress register the signer's address to the Addresslist based on the campaigntime, status and the cap
        pub fun registerAddress (acct : AuthAccount) {
            pre {
                self.Active == true : "The campaign is not active"
                self.checkTime() == true : "The campaign is not active at the moment"
                self.CampaignCap == nil || UInt64(self.Addresslist.keys.length) < self.CampaignCap! : "This Campaign is already full" 
                
            }
            let addr = acct.address
            //case 1 : no cap for this campaign
            if self.CampaignCap == nil {
                self.Addresslist[addr] = true
                //case 2 : There is cap for this campaign
            }else if UInt64(self.Addresslist.keys.length) < self.CampaignCap! {
                self.Addresslist[addr] = true
                
            }
        }


        /* Function for Bulk Addresses Registration (Intended for ths use of Emerald Bot) */ 
        /* Exposed to specific ppl thru Interface : CampaignPrivate */

        // Intakes the list of addresses to be added to the list. Upon max capacity will return a list that fails to register
        pub fun proxyregisterAddress(addrlist : [Address]) : [Address] {
          pre{
                self.Active == true : "The campaign is not active"
                self.checkTime() == true : "The campaign is not active at the moment"
          }
          let registeraddr : [Address] = []
          let remainaddr : [Address] = []

            for addr in addrlist {
                if self.CampaignCap == nil || self.CampaignCap! > UInt64(self.Addresslist.length) {
                self.Addresslist[addr] = true
                registeraddr.append(addr)
                } else {remainaddr.append(addr)}
            }
            return remainaddr
        }

        pub fun checkDistributedCapability(addr : Address) : Bool {
            return self.DistributedCapability.containsKey(addr)
        }

        pub fun addDistributedCapability(addr : Address) {
            self.DistributedCapability[addr] = true
        }

        pub fun removeDistributedCapability(addr : Address) {
            self.DistributedCapability.remove(key: addr)
        }

    }

    // CampaignCollection resource stores 2 major things
    // 1. All Campaigns under the account, and functions around it
    // 2. Store the capability of bulk registration from other accounts
    pub resource CampaignCollection : CampaignCollectionPublic {

        //using Campaign Name as key
        access(contract) var ownedCampaigns : @{String : Campaign}
        access(contract) var ownedCampaignCaps : @{Address : CampaignCollectionCapability}

        init(){
            self.ownedCampaigns <- {}
            self.ownedCampaignCaps <- {}
        }

        destroy () { 
            destroy self.ownedCampaigns
            destroy self.ownedCampaignCaps
        }

        /* Function for CampaignCollection (Storage of campaigns) */

        //Deposit stores the campaign resource to the collection
        pub fun deposit (campaign : @Campaign) {
            let campaignname : String = campaign.CampaignName
            self.ownedCampaigns[campaignname] <-! campaign

        }

        //Remove campaign 
        pub fun removeCampaign (campaignname : String) {
            let campaign <- self.ownedCampaigns.remove(key: campaignname) ?? panic("Cannot find this campaign from collection")
            destroy campaign
        }

        //returns campaigns public reference, everyone can call this
        pub fun borrowCampaignsPublic(campaignname : String) : &Campaign{CampaignPublic} {
            return &self.ownedCampaigns[campaignname] as &Campaign{CampaignPublic}
        }

        //returns campaigns all reference, only the owner can call this
        pub fun borrowCampaigns(campaignname : String) : &Campaign {
            return &self.ownedCampaigns[campaignname] as &Campaign
        }

        //returns a {Campaign Name : Active Status } Map 
        pub fun getCampaigns() : {String : Bool} {
            let campaigns = self.ownedCampaigns.keys
            var maps : {String : Bool} = {}
            for campaign in campaigns {
                maps[campaign] = self.borrowCampaignsPublic(campaignname : campaign).getCampaignStatus() 
            }
            return maps 
        }

        

        /* Function for Capability (Storage of capability to do bulk registration) */

        /* The below 2 functions are for "Deposit of capability function" */
        /* When The resource of the CamapignCollection is created, only deposit the name of the campaign, else create resource */

        pub fun getCampaignCollectionCapabilityRef(addr : Address) : &CampaignCollectionCapability {
            log ("c")
            return &self.ownedCampaignCaps[addr] as &CampaignCollectionCapability
        }

        access(contract) fun depositcapability(campaignaddr : Address, campaigncap : @CampaignCollectionCapability) {
            self.ownedCampaignCaps[campaignaddr] <-! campaigncap
        }

        pub fun addcampaigntocap (campaignaddr : Address, campaignname : String) {
            if !self.getCampaignCollectionCapabilityRef(addr: campaignaddr).campaignnames.contains(campaignname) {
            log ("b")
                self.getCampaignCollectionCapabilityRef(addr: campaignaddr).campaignnames.append(campaignname)
            }
        }

        pub fun giveCap (campaignname : String, receiver : &CampaignCollection{CampaignCollectionPublic}, capability : Capability<&CampaignCollection> ) {
            let campaignaddr = self.owner!.address
            log (campaignaddr)
            let receiveraddr = receiver.owner!.address
            log (receiveraddr)
            if receiver.getCampaignCapslist().containsKey(campaignaddr) {
            log ("a")
                receiver.addcampaigntocap (campaignaddr : campaignaddr, campaignname : campaignname)
            } else {
                receiver.depositcapability(campaignaddr:campaignaddr, campaigncap : <- create CampaignCollectionCapability(_receivedcapability : capability,
                                                                                                _campaignnames : campaignname ,  
                                                                                                _campaignaddr : campaignaddr) )
            }
            log ("d")
            self.borrowCampaigns(campaignname: campaignname).addDistributedCapability(addr: campaignaddr)
            log ("e")

        }

        pub fun revokeCap (campaignname : String, revokeaddr : Address) {
                self.borrowCampaigns(campaignname: campaignname).removeDistributedCapability(addr: revokeaddr)
        }

        pub fun getCampaignCapslist() : {Address : [String]} {
            let campaignaddrs = self.ownedCampaignCaps.keys
            var maps : {Address : [String]} = {}
            for campaignaddr in campaignaddrs {

                let list = self.getCampaignCollectionCapabilityRef(addr: campaignaddr).getCampaignRefList()
                maps[campaignaddr] = list
            }
            return maps 
        }

    }

    pub resource CampaignCollectionCapability {
        access(contract) let receivedcapability : Capability<&CampaignCollection> 
        access(contract) var campaignnames : [String]
        pub let campaignaddr : Address

        init(_receivedcapability : Capability<&CampaignCollection>, _campaignnames : String , _campaignaddr : Address){
            self.receivedcapability = _receivedcapability
            self.campaignnames = [_campaignnames]
            self.campaignaddr = _campaignaddr
        }

        pub fun getCampaginRef(campaignaddr : Address, campaignname : String): &Campaign{CampaignProxyPrivate} {
            post{
                campaignRef.CampaignName == campaignname : "This is not the same campaign as you wanted to borrow"
                campaignRef.owner!.address == campaignaddr : "You are not allowed to borrow this reference"
                campaignRef.checkDistributedCapability(addr: campaignaddr)  : "You are not allowed to borrow this reference"
                
            }
            let campaigncollectionRef = self.receivedcapability.borrow() ?? panic("This capability does not exist")
            let campaignRef : &Campaign{CampaignProxyPrivate} = &campaigncollectionRef.ownedCampaigns[campaignname]as &Campaign{CampaignProxyPrivate}
            return campaignRef

        }

        pub fun getCampaignRefList(): [String]{
            return self.campaignnames
        }

    }
    /* Create Empty Collection Function */

    //Create New Campaign Collection
    pub fun createCampaignCollection() : @CampaignCollection {
        return <- create CampaignCollection()
    }

    /* Create Campaign Function */
    //Create a new campaign and deposit to the collection, using CampaignName as the key
    pub fun createCampaign(to: &CampaignCollection ,CampaignName : String, StartTime : UFix64, EndTime : UFix64, CampaignCap : UInt64) {
        let newcampaign <- create Campaign(_CampaignName : CampaignName, _StartTime : StartTime, _EndTime : EndTime, _CampaignCap : CampaignCap)
        to.deposit(campaign : <- newcampaign)
    }
}