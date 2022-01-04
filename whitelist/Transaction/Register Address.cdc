import CampaignRegister from 0x01

// This transaction is what an account would run
// to set itself up for Collection

transaction (CampaignName : String, CampaignHolderAddress : Address){
    let campaigncollection : &CampaignRegister.CampaignCollection{CampaignRegister.CampaignCollectionPublic}

    prepare(signer: AuthAccount) {
        // Return early if the account already has a collection
        self.campaigncollection = getAccount(CampaignHolderAddress).getCapability(CampaignRegister.CampaignRegisterPublicPath).borrow<&CampaignRegister.CampaignCollection{CampaignRegister.CampaignCollectionPublic}>()
                                            ?? panic("Could not get reference to the Collection")            

        self.campaigncollection.borrowCampaignsPublic(CampaignName: CampaignName).registerAddress(acct: signer)
  
    }

}