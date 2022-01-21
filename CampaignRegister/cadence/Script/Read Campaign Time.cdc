//import CampaignRegister from "./Contract/CampaignRegister.cdc"
import CampaignRegister from 0xc68c624ebbbd3aa9

pub fun main(CampaignName : String , CampaignHolderAddress : Address) : [UFix64?] {

  let campaigncollection = getAccount(CampaignHolderAddress).getCapability(CampaignRegister.CampaignRegisterPublicPath).borrow<&CampaignRegister.CampaignCollection{CampaignRegister.CampaignCollectionPublic}>()
                                            ?? panic("Could not get receiver reference to the Collection")            
  let campaigntime = campaigncollection.borrowCampaignsPublic(campaignname : CampaignName).getCampaignTime()
  return campaigntime
}
