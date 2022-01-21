//import CampaignRegister from "../Contracts/CampaignRegister.cdc"
import CampaignRegister from 0xc68c624ebbbd3aa9

// This transaction is what an account would run
// to set itself up for Collection

transaction () {
    

    prepare(signer: AuthAccount) {
        // Return early if the account already has a collection
        if signer.borrow<&CampaignRegister.CampaignCollection>(from: CampaignRegister.CampaignRegisterStoragePath) != nil {
            let old <- signer.load<@CampaignRegister.CampaignCollection>(from: CampaignRegister.CampaignRegisterStoragePath)
            destroy old
        }
    }
}