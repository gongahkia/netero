import { Address, BigInt } from "@graphprotocol/graph-ts"
import { PollCreated } from "../generated/PollFactory/PollFactory"
import { Poll as PollContract } from "../generated/PollFactory/Poll"
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
  // Try to load on-chain fields directly
  let bound = PollContract.bind(event.params.poll)
  let titleResult = bound.try_title()
  let descResult = bound.try_description()
  let optsResult = bound.try_getOptions()
  let stateResult = bound.try_state()
  let adminResult = bound.try_admin()
  let startResult = bound.try_startTime()
  let endResult = bound.try_endTime()
  let restResult = bound.try_restricted()
  let privResult = bound.try_privateMode()
  let rootResult = bound.try_merkleRoot()

  poll.title = titleResult.reverted ? event.params.title : titleResult.value
  poll.description = descResult.reverted ? "" : descResult.value
  let options: string[] = []
  if (!optsResult.reverted) {
    let arr = optsResult.value
    for (let i = 0; i < arr.length; i++) {
      options.push(arr[i])
    }
  }
  poll.options = options
  let zeros: BigInt[] = []
  for (let i = 0; i < options.length; i++) {
    zeros.push(BigInt.fromI32(0))
  }
  poll.tallies = zeros
  poll.state = stateResult.reverted ? 0 : stateResult.value
  poll.admin = adminResult.reverted ? event.params.creator : adminResult.value
  poll.createdAt = event.block.timestamp
  poll.startTime = startResult.reverted ? BigInt.fromI32(0) : startResult.value
  poll.endTime = endResult.reverted ? BigInt.fromI32(0) : endResult.value
  poll.restricted = restResult.reverted ? false : restResult.value
  poll.privateMode = privResult.reverted ? false : privResult.value
  poll.merkleRoot = rootResult.reverted ? Address.zero() : rootResult.value
  poll.save()
}
