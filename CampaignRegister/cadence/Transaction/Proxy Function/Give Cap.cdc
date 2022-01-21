//import CampaignRegister from "../../Contract/CampaignRegister.cdc"
import CampaignRegister from 0xc68c624ebbbd3aa9

transaction (CampaignName : String, receiveraddr : Address){
    

    prepare(signer: AuthAccount) {

        // Borrow the reference

        let campaigncollectionCap = signer.getCapability<&CampaignRegister.CampaignCollection>(CampaignRegister.CampaignRegisterPrivatePath)

        let campaigncollectionRef = signer.borrow<&CampaignRegister.CampaignCollection>(from: CampaignRegister.CampaignRegisterStoragePath) ??panic("Cannot borrow the receivercollection reference")

        let receivercollectionCap = getAccount(receiveraddr).getCapability(CampaignRegister.CampaignRegisterPublicPath)

        let receivercollectionRef = receivercollectionCap.borrow<&CampaignRegister.CampaignCollection{CampaignRegister.CampaignCollectionPublic}>() ??panic("Cannot borrow the receivercollection reference")

        campaigncollectionRef.giveCap(campaignname: CampaignName, receiver: receivercollectionRef, capability: campaigncollectionCap)


    }
}