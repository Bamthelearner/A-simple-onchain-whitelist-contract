import CampaignRegister from "./Contract/CampaignRegister.cdc"


pub fun main(CampaignHolderAddress : Address) : {String : Bool} {

  let campaigncollection = getAccount(CampaignHolderAddress).getCapability(CampaignRegister.CampaignRegisterPublicPath).borrow<&CampaignRegister.CampaignCollection{CampaignRegister.CampaignCollectionPublic}>()
                                            ?? panic("Could not get receiver reference to the Collection")            
  let campaigns = campaigncollection.getCampaigns()
  return campaigns
}
