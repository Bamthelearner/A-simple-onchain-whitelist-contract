pub contract CampaignRegister {


    //Resource interface of campaign, disclose the function to the public
    pub resource interface CampaignPublic {

        pub let CampaignName : String

        pub fun getAddress () : [Address]
        pub fun registerAddress (acct : AuthAccount)
        pub fun getCampaignStatus() : Bool
        pub fun getCampaignCap () : UInt64?
        pub fun getCampaignTime() : [UFix64?]

    } 

    //Resource interface of campaign, disclose the proxy function to the the Emerald Bot for bulk adding addresses to list
    pub resource interface CampaignProxyInterface {
        pub let CampaignName : String
        pub fun getAddress () : [Address]
        pub fun registerAddress (acct : AuthAccount)
        pub fun getCampaignStatus() : Bool
        pub fun getCampaignCap () : UInt64?
        pub fun getCampaignTime() : [UFix64?]

        pub fun proxyregisterAddress(_ ProxyAdrres : Address, Addresslist : [Address]) : [Address]
    } 

    //Campaign resource stores all the function , information and register addresses.
    pub resource Campaign : CampaignPublic, CampaignProxyInterface{
        //CampaignName acts as a unique key to map to the campaign resources in campaign collection
        pub let CampaignName : String

        //Addresslist stores all the address registered to the campaign in a dictionary
        access(contract) var Addresslist : {Address : Bool}

        //Active regulates the address registration status, false will disable registration function
        pub var Active : Bool
        //StartTime and EndTime of a campaign regulated the registration status, registration function is disabled outside the time
        pub var StartTime : UFix64?
        pub var EndTime: UFix64?

        //CampaignCap is the maximum intake of this campaign, the registration stops after the cap is reached.
        pub var CampaignCap : UInt64?


        //getAddress returns a list of registered addresses in array
        pub fun getAddress () : [Address]{


        //getCampaignCap returns the cap of the campaign registration
        pub fun getCampaignCap () : UInt64? {


        //checkTime returns true / false on whether the campaign registration is within the time
        pub fun checkTime () : Bool {


        //registerAddress register the signer's address to the Addresslist based on the campaigntime, status and the cap
        pub fun registerAddress (acct : AuthAccount) {


        //getCampaignStatus returns whether the campaign is active
        pub fun getCampaignStatus() : Bool {


        //Admin Function
        //toggleCampaignStatus takes in a Bool to change the status of the campaign
        pub fun toggleCampaignStatus(Status : Bool) {


        //getCampaignTime returns the campaign start and end time
        pub fun getCampaignTime() : [UFix64?]{

        //Admin Function --> only callable when the campaign registration is not active
        //changeCampaignTime takes in Start and End Time to change the campaign time
        pub fun changeCampaignTime(Start : UFix64, End : UFix64) {


        //Admin Function --> only callable when the campaign registration is not active
        //changeCampaignCap changes the campaign capacity
        pub fun changeCampaignCap(newCap : UInt64) {


        //Admin Function --> only callable when the campaign registration is not active
        //removeAddress remove an address from the list
        pub fun removeAddress (address : Address) {


        //Proxy Funciton --> only allowed for the proxy to call
        //Add addresses in bulk the addresses that are not added (due to exceeding max cap) will be returned as an array)
        pub fun proxyregisterAddress(_ ProxyAdrres : Address, Addresslist : [Address]) : [Address] {

        

    }

    //Create a new campaign and deposit to the collection, using CampaignName as the key
    pub fun createCampaign(to: &CampaignCollection ,CampaignName : String, StartTime : UFix64, EndTime : UFix64, CampaignCap : UInt64) {


    //Resource interface of CampaignCollection, disclose the function to the public
    pub resource interface CampaignCollectionPublic {

        pub fun borrowCampaignsPublic(CampaignName : String) : &Campaign{CampaignPublic}
        pub fun getCampaigns() : {String : Bool}
        
    }

    pub resource interface CampaignProxyPublic {
        pub fun borrowCampaignProxy (address : Address , campaignname : String) : &Campaign{CampaignProxyInterface}
    }

    //Resource CampaignCollection stores campaigns using Campaign Name as key
    pub resource CampaignCollection : CampaignCollectionPublic , CampaignProxyPublic {

        //using Campaign Name as key
        access(contract) var ownedCampaigns : @{String : Campaign}
        access(contract) var ownedCampaignProxies : {Address : ProxyDictionary}


        //Deposit stores the campaign resource to the collection
        pub fun deposit (campaign : @Campaign) {


        //Remove campaign takes out the campaign resource and returns it (Should be destroyed or handled in the trxn for safety)
        pub fun removeCampaign (campaignname : String) : @Campaign{


        //returns campaigns public reference, everyone can call this
        pub fun borrowCampaignsPublic(CampaignName : String) : &Campaign{CampaignPublic} {


        //returns campaigns all reference, only the owner can call this
        pub fun borrowCampaigns(CampaignName : String) : &Campaign {


        //returns a {Campaign Name : Active Status } Map 
        pub fun getCampaigns() : {String : Bool} {


        //
        pub fun borrowCampaignProxy (address : Address , campaignname : String) : &Campaign{CampaignProxyInterface} {

        //Deposit stores the campaign resource to the collection
        pub fun depositProxy (campaign : @Campaign, campaignCap : Capability<&Campaign{CampaignProxyInterface}>) {


    }

    // A struct that stores all proxy capabilities to 1 of the addresses
    pub struct ProxyDictionary {
        access(contract) var dictionary : {String : Capability<&Campaign{CampaignProxyInterface}>}

        pub fun keys() : [String] {
            return self.dictionary.keys
        }

        pub fun deposit (campaignproxyCap : Capability<&Campaign{CampaignProxyInterface}>) {


        access(contract) fun getProxy(campaignname : String) : &Campaign{CampaignProxyInterface} {

    }

    //Create New Campaign Collection
    pub fun createCampaignCollection() : @CampaignCollection {
        return <- create CampaignCollection()
    }

}