import CampaignRegister from "./Contract/CampaignRegister.cdc"


pub fun main(CampaignName : String , CampaignHolderAddress : Address) : [Address] {

  let campaigncollection = getAccount(CampaignHolderAddress).getCapability(CampaignRegister.CampaignRegisterPublicPath).borrow<&CampaignRegister.CampaignCollection{CampaignRegister.CampaignCollectionPublic}>()
                                            ?? panic("Could not get receiver reference to the Collection")            
  let campaignaddress = campaigncollection.borrowCampaignsPublic(CampaignName : CampaignName).getAddress()
  return campaignaddress
}
