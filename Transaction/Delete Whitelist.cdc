import Whitelisting from 0x01

transaction(Project: String) {
    prepare(signer: AuthAccount) {
        let whitelistcollection = signer.getCapability(/private/WhitelistCollection).borrow<&Whitelisting.WhitelistCollection>()
            ?? panic("Could not borrow a reference to the owner's collection")

        // withdraw the NFT from the owner's collection
        whitelistcollection.removewhitelist(Project: Project)

    }
}

