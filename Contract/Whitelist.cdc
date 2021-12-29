pub contract Whitelisting {

    pub event WhitelistAdded(by: Address, Project: String)
    pub event WhitelistRemoved(by: Address, Project: String)

    pub resource interface WhitelistPublic {
        pub fun getAddresses(): [Address]
        pub fun registerAddress(acct : AuthAccount)
        pub let Project : String
        pub let ProjectContract : Address
    }
    
    pub resource interface WhitelistGovernor {
        access(contract) fun removeAddress(address : Address)
    }

    pub resource Whitelist: WhitelistPublic, WhitelistGovernor {
        access(contract) var Addresses: {Address: Bool}
        pub let Project : String
        pub let ProjectContract : Address
        pub var Active : Bool


        pub fun registerAddress(acct : AuthAccount) {
            if self.Active {
                let acctaddress = acct.address
                self.Addresses[acctaddress] = true
            }
        }

        access(contract) fun removeAddress(address : Address) {
            self.Addresses.remove(key: address) ?? panic("missing Address")
        }

        pub fun getAddresses(): [Address] {
            return self.Addresses.keys
        }

        pub fun getWhiteliststatus() : Bool{
            return self.Active
        }

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

    pub resource interface WhitelistCollectionPublic{
        pub var ownedWhitelists: @{String: Whitelist}
        pub fun borrowWhitelists(Project: String): &Whitelist
        pub fun getWhitelists(): [String]
    }

    pub resource WhitelistCollection: WhitelistCollectionPublic {
        // dictionary of Whitelists
        // Whitelist is a resource type with an `UInt64` ID field
        pub var ownedWhitelists: @{String : Whitelist}

        init () {
            self.ownedWhitelists <- {}
        }

        access(contract) fun deposit(whitelist: @Whitelist) {
            let Project: String = whitelist.Project

            // add the new token to the dictionary which removes the old one
            let oldwhitelist <- self.ownedWhitelists[Project] <- whitelist

            emit WhitelistAdded (by: self.owner!.address, Project: Project)

            destroy oldwhitelist
        }

        // withdraw removes an NFT from the collection and moves it to the caller
        pub fun removewhitelist(Project: String) {
            let token <- self.ownedWhitelists.remove(key: Project) ?? panic("missing Whitelist")

            emit WhitelistRemoved(by: self.owner!.address, Project: Project)

            destroy token
        }

        // getIDs returns an array of the IDs that are in the collection
        pub fun getWhitelists(): [String] {
            return self.ownedWhitelists.keys
        }

        pub fun removeAddressfromWhitelist(address : Address, Project : String){
            let whitelistRef : &Whitelist = &self.ownedWhitelists[Project] as &Whitelist  
            whitelistRef.removeAddress(address : address)
        }

        pub fun toggleWhiteliststatus(active: Bool, Project : String){
            let whitelistRef : &Whitelist = &self.ownedWhitelists[Project] as &Whitelist  
            whitelistRef.togglestatus(active: active)
        }

        // borrowNFT gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        pub fun borrowWhitelists(Project: String): &Whitelist {
            return &self.ownedWhitelists[Project] as &Whitelist
        }

        destroy() {
            destroy self.ownedWhitelists
        }
    }

    pub fun createWhitelistCollection() : @WhitelistCollection {
        return <- create WhitelistCollection()
    }

}