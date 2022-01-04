import CampaignRegister from "./Contract/CampaignRegister.cdc"

transaction(CampaignName: String) {
    prepare(signer: AuthAccount) {
        let campaigncollection = signer.borrow<&CampaignRegister.CampaignCollection>(from: CampaignRegister.CampaignRegisterStoragePath)
            ?? panic("Could not borrow a reference to the owner's collection")

        // Remove the campaign from the collection
        let oldcampaign <- campaigncollection.removeCampaign(campaignname: CampaignName)

        // Explicitly destroy the campaign
        destroy oldcampaign

    }
}

