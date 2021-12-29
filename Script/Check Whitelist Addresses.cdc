import Whitelisting from "../Contract/Whitelist.cdc"


pub fun main(Project : String , ProjectContract : Address) {

  let whitelistcollection = getAccount(ProjectContract).getCapability(/public/WhitelistCollection).borrow<&Whitelisting.WhitelistCollection{Whitelisting.WhitelistCollectionPublic}>()
                                            ?? panic("Could not get receiver reference to the Collection")            
  log(whitelistcollection.borrowWhitelists(Project : Project))
    
}
