import CampaignRegister from "./Contract/CampaignRegister.cdc"


pub fun main(CampaignName : String , CampaignHolderAddress : Address) : Bool {

  let campaigncollection = getAccount(CampaignHolderAddress).getCapability(CampaignRegister.CampaignRegisterPublicPath).borrow<&CampaignRegister.CampaignCollection{CampaignRegister.CampaignCollectionPublic}>()
                                            ?? panic("Could not get receiver reference to the Collection")            
  let campaignstatus = campaigncollection.borrowCampaignsPublic(CampaignName : CampaignName).getCampaignStatus()
  return campaignstatus
}
