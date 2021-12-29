import Whitelisting from 0x01

// This transaction is what an account would run
// to set itself up for WhitelistCollection

transaction (Project : String, ProjectContract : Address){
    let whitelistcollection : &Whitelisting.WhitelistCollection{Whitelisting.WhitelistCollectionPublic}

    prepare(signer: AuthAccount) {
        // Return early if the account already has a collection
        self.whitelistcollection = getAccount(ProjectContract).getCapability(/public/WhitelistCollection).borrow<&Whitelisting.WhitelistCollection{Whitelisting.WhitelistCollectionPublic}>()
                                            ?? panic("Could not get reference to the Collection")            

        self.whitelistcollection.borrowWhitelists(Project: Project).registerAddress(acct: signer)
  
    }

}