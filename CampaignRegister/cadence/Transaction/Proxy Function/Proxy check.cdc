//import CampaignRegister from "./Contract/CampaignRegister.cdc"
import CampaignRegister from 0xc68c624ebbbd3aa9

pub fun main(CampaignName : String , CampaignHolderAddress : Address) : {Address : [String]} {

  let campaigncollection = getAccount(CampaignHolderAddress).getCapability(CampaignRegister.CampaignRegisterPublicPath).borrow<&CampaignRegister.CampaignCollection{CampaignRegister.CampaignCollectionPublic}>()
                                            ?? panic("Could not get receiver reference to the Collection")            
  let campaigntime = campaigncollection.getCampaignCapslist()
  return campaigntime
}
