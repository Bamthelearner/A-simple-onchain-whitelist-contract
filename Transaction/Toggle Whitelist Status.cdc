import Whitelisting from 0x01

transaction(Project: String, active : Bool) {
    prepare(signer: AuthAccount) {
        let whitelistcollection = signer.borrow<&Whitelisting.WhitelistCollection>(from: /storage/WhitelistCollection)
            ?? panic("Could not borrow a reference to the owner's collection")

        // Toggle the whitelist to enable / disable the registry
        whitelistcollection.toggleWhiteliststatus(active: active, Project: Project)

    }
}

