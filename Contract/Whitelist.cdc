pub contract Whitelisting {

    pub event WhitelistAdded(by: Address, Project: String)
    pub event WhitelistRemoved(by: Address, Project: String)

    //This is a resource interface that disclose the Whitelist function to the public
    //But I think this is not employed...
    pub resource interface WhitelistPublic {
        pub fun getAddresses(): [Address]
        pub fun registerAddress(acct : AuthAccount)
        pub let Project : String
        pub let ProjectContract : Address
        pub fun getWhiteliststatus() : Bool
    }

    //This is a resource interface that disclose the Whitelist function to the specific goveners
    //But I think this is not employed...   
    pub resource interface WhitelistGovernor {
        access(contract) fun removeAddress(address : Address)
    }

    // Resource Whitelist contains an Address to bool map that can protect double address entry and 
    // enables remove with address (key)
    pub resource Whitelist: WhitelistPublic, WhitelistGovernor {
        access(contract) var Addresses: {Address: Bool}
        pub let Project : String
        pub let ProjectContract : Address
        pub var Active : Bool

        //This function enables users to register their address to the whitelist (Whitelisted)
        pub fun registerAddress(acct : AuthAccount) {
            if self.Active {
                let acctaddress = acct.address
                self.Addresses[acctaddress] = true
            }
        }

        //This function enables admin to remove any address from the whitelist
        access(contract) fun removeAddress(address : Address) {
            self.Addresses.remove(key: address) ?? panic("missing Address")
        }

        //return an array of register addresses
        pub fun getAddresses(): [Address] {
            return self.Addresses.keys
        }

        //return a boolean to show the status of the whitelist
        pub fun getWhiteliststatus() : Bool{
            return self.Active
        }

        //This function enables admin to toggle the registry status of the whitelist
        access(contract) fun togglestatus(active : Bool ) {
            self.Active = active
        } 

        init(_Project : String , _ProjectContract : Address) {
            self.Addresses = {}
            self.Project = _Project
            self.ProjectContract = _ProjectContract
            self.Active = false
        }
    }

    pub fun createWhitelist(to: &WhitelistCollection, Project : String, ProjectContract: Address) {

        // create a new Whitelist
        var newWhitelist <- create Whitelist(_Project : Project , _ProjectContract : ProjectContract)

        // deposit it in the recipient's account using their reference
        to.deposit(whitelist: <-newWhitelist)
        
    }

    //This is a resource interface that disclose the WhitelistCollection function to the public
    pub resource interface WhitelistCollectionPublic{
        pub fun borrowWhitelists(Project: String): &Whitelist{WhitelistPublic}
        pub fun getWhitelists(): {String:Bool}
    }

    //This is a resource that contains the Whitelist to enable multi whitelisting for an account
    //The whitelists are mapped to the unique project name
    pub resource WhitelistCollection: WhitelistCollectionPublic {
        // dictionary of Whitelists
        // Whitelist is a resource type with an `UInt64` ID field
        pub var ownedWhitelists: @{String : Whitelist}

        init () {
            self.ownedWhitelists <- {}
        }

        access(contract) fun deposit(whitelist: @Whitelist) {
            let Project: String = whitelist.Project

            // add the new whitelist to the dictionary which removes the old one
            let oldwhitelist <- self.ownedWhitelists[Project] <- whitelist

            emit WhitelistAdded (by: self.owner!.address, Project: Project)

            destroy oldwhitelist
        }

        // removes a whitelist
        pub fun removewhitelist(Project: String) {
            let token <- self.ownedWhitelists.remove(key: Project) ?? panic("missing Whitelist")

            emit WhitelistRemoved(by: self.owner!.address, Project: Project)

            destroy token
        }

        // returns an array of the projects that are in the collection
        pub fun getWhitelists(): {String:Bool} {
            let maps : {String : Bool} = {}
            let whitelists = self.ownedWhitelists.keys
            for whitelist in whitelists{
                let map = &self.ownedWhitelists[whitelist] as &Whitelist
                maps[whitelist] = map.getWhiteliststatus()
            }
            return maps
        }

        // removes an address from a specific project whitelist
        pub fun removeAddressfromWhitelist(address : Address, Project : String){
            let whitelistRef : &Whitelist = &self.ownedWhitelists[Project] as &Whitelist  
            whitelistRef.removeAddress(address : address)
        }

        // toggle the state of the whitelist
        pub fun toggleWhiteliststatus(active: Bool, Project : String){
            let whitelistRef : &Whitelist = &self.ownedWhitelists[Project] as &Whitelist  
            whitelistRef.togglestatus(active: active)
        }

        // gets a reference to a whitelist in the collection
        // so that the caller can read its data and call its methods
        pub fun borrowWhitelists(Project: String): &Whitelist{WhitelistPublic} {
            return &self.ownedWhitelists[Project] as &Whitelist{WhitelistPublic}
        }

        destroy() {
            destroy self.ownedWhitelists
        }
    }

    pub fun createWhitelistCollection() : @WhitelistCollection {
        return <- create WhitelistCollection()
    }

}