import CampaignRegister from 0x01

// This transaction is what an account would run
// to set itself up for Collection

transaction (CampaignName : String, status : Bool){
    let campaigncollection : &CampaignRegister.CampaignCollection

    prepare(signer: AuthAccount) {
        // Return early if the account already has a collection
        self.campaigncollection = signer.borrow<&CampaignRegister.CampaignCollection>(from:CampaignRegister.CampaignRegisterStoragePath)
                                            ?? panic("Could not get reference to the Collection")            

        let campaignRef = self.campaigncollection.borrowCampaigns(CampaignName: CampaignName)
        campaignRef.toggleCampaignStatus(Status: status)

  
    }

}