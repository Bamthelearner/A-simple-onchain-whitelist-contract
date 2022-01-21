//import CampaignRegister from "../../Contracts/CampaignRegister.cdc"
import CampaignRegister from 0xc68c624ebbbd3aa9

// This transaction is what an account would run
// to set itself up for Collection

transaction (CampaignName : String, Campaignaddr : Address, addrlist: [Address]){
    

    prepare(signer: AuthAccount) {

        // Borrow the reference

        let campaigncollectionRef = signer.borrow<&CampaignRegister.CampaignCollection>(from: CampaignRegister.CampaignRegisterStoragePath) ??panic("Cannot borrow the receivercollection reference")

        campaigncollectionRef.getCampaignCollectionCapabilityRef(addr: Campaignaddr)
                            .getCampaginRef(campaignaddr: Campaignaddr, campaignname: CampaignName)
                            .proxyregisterAddress(addrlist: addrlist)
        
    }
}