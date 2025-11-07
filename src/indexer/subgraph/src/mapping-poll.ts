import { BigInt } from "@graphprotocol/graph-ts"
import { Voted, StateChanged, VoteRevealed } from "../generated/Poll/Poll"
import { Poll, Vote } from "../generated/schema"

export function handleVoted(event: Voted): void {
  const pollId = event.address.toHex()
  let poll = Poll.load(pollId)
  if (poll == null) return

  // increment tally at optionIndex
  const idx = event.params.optionIndex.toI32()
  let tallies = poll.tallies
  if (idx >= 0 && idx < tallies.length) {
    tallies[idx] = tallies[idx].plus(BigInt.fromI32(1))
    poll.tallies = tallies
    poll.save()
  }

  const vote = new Vote(event.transaction.hash.toHex() + ":" + event.logIndex.toString())
  vote.poll = pollId
  vote.voter = event.params.voter
  vote.optionIndex = idx
  vote.blockNumber = event.block.number
  vote.timestamp = event.block.timestamp
  vote.save()
}

// Optional: ensure reveal also bumps tallies in private mode
export function handleVoteRevealed(event: VoteRevealed): void {
  handleVoted(changetype<Voted>(event))
}

export function handleStateChanged(event: StateChanged): void {
  const pollId = event.address.toHex()
  let poll = Poll.load(pollId)
  if (poll == null) return
  poll.state = event.params.newState
  poll.save()
}
