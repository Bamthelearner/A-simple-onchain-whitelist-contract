import Whitelisting from 0x01

// This transaction is what an account would run
// to set itself up for WhitelistCollection

transaction (Project : String){
    

    prepare(signer: AuthAccount) {
        // Return early if the account already has a collection
        if signer.borrow<&Whitelisting.WhitelistCollection>(from: /storage/WhitelistCollection) != nil {
            return
        }else{

            // Create a new empty collection
            let collection <- Whitelisting.createWhitelistCollection()

            // save it to the account
            signer.save(<-collection, to: /storage/WhitelistCollection)

            // create a public capability for the collection
            signer.link<&Whitelisting.WhitelistCollection{Whitelisting.WhitelistCollectionPublic}>(/public/WhitelistCollection, target: /storage/WhitelistCollection)

        }
        // Borrow the reference
        let whitelistcollection = signer.borrow<&Whitelisting.WhitelistCollection>(from: /storage/WhitelistCollection)
                                        ?? panic("Could not get receiver reference to the NFT Collection")
        

        Whitelisting.createWhitelist(to: whitelistcollection, Project : Project, ProjectContract: signer.address)
    }
}