import Whitelisting from 0x01

transaction(Project: String, active : Bool) {
    prepare(signer: AuthAccount) {
        let whitelistcollection = signer.borrow<&Whitelisting.WhitelistCollection>(from: /storage/WhitelistCollection)
            ?? panic("Could not borrow a reference to the owner's collection")

        // withdraw the NFT from the owner's collection
        whitelistcollection.toggleWhiteliststatus(active: active, Project: Project)

    }
}

