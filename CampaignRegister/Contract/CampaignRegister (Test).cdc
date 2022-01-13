pub contract CampaignRegister {
    // Stores the public path of public capability and storage path
    pub let CampaignRegisterPublicPath : PublicPath
    pub let CmapaignRegisterPrivatePath : PrivatePath
    pub let CampaignRegisterStoragePath : StoragePath

    init () {
        self.CampaignRegisterPublicPath = /public/campaignregistercollection
        self.CmapaignRegisterPrivatePath = /private/campaignregistercollection
        self.CampaignRegisterStoragePath = /storage/campaignregistercollection
    }

    //Emit event when a campaign is created
    pub event CampaignAdded (by : Address? , CampaignName : String, CampaignHolderAddress : Address?)
    //Emit event when a campaign is removed (Admin remove is not acknowleged atm)
    pub event CampaignRemoved (by : Address? , CampaignName : String, CampaignHolderAddress : Address?)
    //Emit event when an address is added to the list
    pub event AddressAddedtoCampaign (by : Address?, Address : Address, CampaignName : String, CampaignHolderAddress : Address?)
    //Emit event when an address is deleted from the list
    pub event AddressRemovedfromCampaign (by : Address?, Address : Address, CampaignName : String, CampaignHolderAddress : Address)
    //Emit event when Campaign status toggles
    pub event CampaignStatusToggle (by: Address?, CampaignName : String, CampaignHolderAddress : Address, 
                                    StartTimeBefore : UFix64, EndTimeBefore : UFix64, CapacityBefore : UInt64,
                                    StartTimeAfter : UFix64, EndTimeAfter : UFix64, CapacityAfter : UInt64)

    //Resource interface of campaign, disclose the function to the public
    pub resource interface CampaignPublic {

        pub let CampaignName : String

        pub fun getAddress () : [Address]
        pub fun registerAddress (acct : AuthAccount)
        pub fun getCampaignStatus() : Bool
        pub fun getCampaignCap () : UInt64?
        pub fun getCampaignTime() : [UFix64?]



    } 

    pub resource interface CampaignProxyPrivate {
        pub let CampaignName : String
        pub fun proxyregisterAddress(addrlist : [Address]) : [Address] 
        pub fun checkDistributedCapability(addr : Address) : Bool
    }


    //Campaign resource stores all the function , information and register addresses.
    pub resource Campaign : CampaignPublic, CampaignProxyPrivate{
        //CampaignName acts as a unique key to map to the campaign resources in campaign collection
        pub let CampaignName : String

        //Addresslist stores all the address registered to the campaign in a dictionary
        access(contract) var Addresslist : {Address : Bool}

        //
        access(contract) var DistributedCapability : {Address : Bool}

        //Active regulates the address registration status, false will disable registration function
        pub var Active : Bool
        //StartTime and EndTime of a campaign regulated the registration status, registration function is disabled outside the time
        pub var StartTime : UFix64?
        pub var EndTime: UFix64?

        //CampaignCap is the maximum intake of this campaign, the registration stops after the cap is reached.
        pub var CampaignCap : UInt64?

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

        //checkTime returns true / false on whether the campaign registration is within the time
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
            let address = acct.address
            //case 1 : no cap for this campaign
            if self.CampaignCap == nil {
                self.Addresslist[address] = true
                //case 2 : There is cap for this campaign
            }else if UInt64(self.Addresslist.keys.length) < self.CampaignCap! {
                self.Addresslist[address] = true
                
            }
        }



        //Admin Function
        //toggleCampaignStatus takes in a Bool to change the status of the campaign
        pub fun toggleCampaignStatus(Status : Bool) {
            self.Active = Status
        }



        //Admin Function --> only callable when the campaign registration is not active
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

        //Admin Function --> only callable when the campaign registration is not active
        //removeAddress remove an address from the list
        pub fun removeAddress (address : Address) {
            pre {
                self.Active == false : "Admin Function has to be performed after deactivate the campaign registration"
            }

            self.Addresslist.remove(key: address) ??panic ("Cannot find this address from the registry")
            
        }

        /* Proxy Function */
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

    }

    //Create a new campaign and deposit to the collection, using CampaignName as the key
    pub fun createCampaign(to: &CampaignCollection ,CampaignName : String, StartTime : UFix64, EndTime : UFix64, CampaignCap : UInt64) {
        let newcampaign <- create Campaign(_CampaignName : CampaignName, _StartTime : StartTime, _EndTime : EndTime, _CampaignCap : CampaignCap)
        emit CampaignAdded(by : newcampaign.owner?.address, CampaignName : newcampaign.CampaignName, CampaignHolderAddress : newcampaign.owner?.address)
        to.deposit(campaign : <- newcampaign)
    }

    //Resource interface of CampaignCollection, disclose the function to the public
    pub resource interface CampaignCollectionPublic {

        pub fun borrowCampaignsPublic(CampaignName : String) : &Campaign{CampaignPublic}
        pub fun getCampaigns() : {String : Bool}
        pub fun getCampaignCapslist() : {Address : [String]} 

        access(contract) fun addcampaigntocap (campaignaddr : Address, campaignname : String) 
        access(contract) fun depositcapability(campaignaddr : Address, campaigncap : @CampaignCollectionCapability)
    }



    //Resource CampaignCollection stores campaigns using Campaign Name as key
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

        //Deposit stores the campaign resource to the collection
        pub fun deposit (campaign : @Campaign) {
            let campaignname : String = campaign.CampaignName
            self.ownedCampaigns[campaignname] <-! campaign

        }

        //Remove campaign takes out the campaign resource and returns it (Should be destroyed or handled in the trxn for safety)
        pub fun removeCampaign (campaignname : String) : @Campaign{
            let campaign <- self.ownedCampaigns.remove(key: campaignname) ?? panic("Cannot find this campaign from collection")
            emit CampaignRemoved(by : campaign.owner?.address, CampaignName : campaign.CampaignName, CampaignHolderAddress : campaign.owner?.address)
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

        /* Capability functions */

        //
        pub fun getCampaignCollectionCapabilityRef(addr : Address) : &CampaignCollectionCapability {
            return &self.ownedCampaignCaps[addr] as &CampaignCollectionCapability
        }

        //returns a {Campaign Address : [Campaign] } Map 
        pub fun getCampaignCapslist() : {Address : [String]} {
            let campaignaddrs = self.ownedCampaignCaps.keys
            var maps : {Address : [String]} = {}
            for campaignaddr in campaignaddrs {

                let list = self.getCampaignCollectionCapabilityRef(addr: campaignaddr).getCampaignRefList()
                maps[campaignaddr] = list
            }
            return maps 
        }

        access(contract) fun depositcapability(campaignaddr : Address, campaigncap : @CampaignCollectionCapability) {
            self.ownedCampaignCaps[campaignaddr] <-! campaigncap
        }

        access(contract) fun addcampaigntocap (campaignaddr : Address, campaignname : String) {
            self.getCampaignCollectionCapabilityRef(addr: campaignaddr).campaignnames.append(campaignname)
        }

        pub fun giveCap (campaignname : String, receiver : &CampaignCollection{CampaignCollectionPublic}, capability : Capability<&CampaignCollection> ) {
            let campaignaddr = self.owner!.address
            let receiveraddr = receiver.owner!.address
            if receiver.getCampaignCapslist().containsKey(campaignaddr) {
                receiver.depositcapability(campaignaddr:campaignaddr, campaigncap : <- create CampaignCollectionCapability(_receivedcapability : capability,
                                                                                                _campaignnames : campaignname ,  
                                                                                                _campaignaddr : campaignaddr) )
            } else {
                receiver.addcampaigntocap (campaignaddr : campaignaddr, campaignname : campaignname)
            }
                self.borrowCampaigns(CampaignName: campaignname).DistributedCapability.insert(key: campaignaddr, true)

        }

    }


  //Create New Campaign Collection
  pub fun createCampaignCollection() : @CampaignCollection {
      return <- create CampaignCollection()
  }

  pub resource CampaignCollectionCapability {
    access(contract) let receivedcapability : Capability<&CampaignCollection> 
    pub let campaignnames : [String]
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

}