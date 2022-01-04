import CampaignRegister from 0x01

// This transaction is what an account would run
// to set itself up for Collection

transaction (CampaignName : String, StartTime : UFix64, EndTime : UFix64, CampaignCap : UInt64){
    

    prepare(signer: AuthAccount) {
        // Return early if the account already has a collection
        if signer.borrow<&CampaignRegister.CampaignCollection>(from: CampaignRegister.CampaignRegisterStoragePath) != nil {
            return
        }else{

            // Create a new empty collection
            let collection <- CampaignRegister.createCampaignCollection()

            // save it to the account
            signer.save(<-collection, to: CampaignRegister.CampaignRegisterStoragePath)

            // create a public capability for the collection
            signer.link<&CampaignRegister.CampaignCollection{CampaignRegister.CampaignCollectionPublic}>(CampaignRegister.CampaignRegisterPublicPath, target: CampaignRegister.CampaignRegisterStoragePath)

        }
        // Borrow the reference
        let campaigncollection = signer.borrow<&CampaignRegister.CampaignCollection>(from: CampaignRegister.CampaignRegisterStoragePath)
                                        ?? panic("Could not get receiver reference to the Collection")
        

        CampaignRegister.createCampaign(to: campaigncollection, CampaignName: CampaignName, StartTime: StartTime, EndTime: EndTime, CampaignCap: CampaignCap)
    }
}