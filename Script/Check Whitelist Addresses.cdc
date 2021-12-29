import Whitelisting from 0x01


pub fun main(Project : String , ProjectContract : Address) : [Address] {

  let whitelistcollection = getAccount(ProjectContract).getCapability(/public/WhitelistCollection).borrow<&Whitelisting.WhitelistCollection{Whitelisting.WhitelistCollectionPublic}>()
                                            ?? panic("Could not get receiver reference to the Collection")            
  let whitelistaddresses = whitelistcollection.borrowWhitelists(Project : Project).getAddresses()
  return whitelistaddresses
}
