import Whitelisting from 0x01

transaction(Project: String) {
    prepare(signer: AuthAccount) {
        let whitelistcollection = signer.borrow<&Whitelisting.WhitelistCollection>(from: /storage/WhitelistCollection)
            ?? panic("Could not borrow a reference to the owner's collection")

        // Remove the entire whitelist from the collection
        whitelistcollection.removewhitelist(Project: Project)

    }
}

