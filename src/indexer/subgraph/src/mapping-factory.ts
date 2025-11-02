import { Address, BigInt } from "@graphprotocol/graph-ts"
import { PollCreated } from "../generated/PollFactory/PollFactory"
import { Org, Poll } from "../generated/schema"

export function handlePollCreated(event: PollCreated): void {
  let orgId = event.params.org.toHex()
  let org = Org.load(orgId)
  if (org == null) {
    org = new Org(orgId)
  }
  org.save()

  let poll = new Poll(event.params.poll.toHex())
  poll.org = orgId
  poll.title = event.params.title
  poll.description = ""
  poll.options = []
  poll.tallies = []
  poll.state = 0
  poll.admin = event.params.creator
  poll.createdAt = event.block.timestamp
  poll.save()
}
