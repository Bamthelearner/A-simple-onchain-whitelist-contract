import CampaignRegister from 0x01


pub fun main(CampaignName : String , CampaignHolderAddress : Address) : UInt64 {

  let campaigncollection = getAccount(CampaignHolderAddress).getCapability(CampaignRegister.CampaignRegisterPublicPath).borrow<&CampaignRegister.CampaignCollection{CampaignRegister.CampaignCollectionPublic}>()
                                            ?? panic("Could not get receiver reference to the Collection")            
  let campaigncap = campaigncollection.borrowCampaignsPublic(CampaignName : CampaignName).getCampaignCap()
  return campaigncap
}
