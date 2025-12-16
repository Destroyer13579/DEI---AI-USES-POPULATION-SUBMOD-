# **DEI SubMod: AI USES POPULATION AND MORE v0.4.1 — PRE-RELEASE** 

 Status: Experimental, but working in testing. Save-game ready (restart preferred).

### **What this mod does**

This submod enforces full population-based constraints on the AI, placing it under the same demographic, recruitment, and recovery rules as the player.

When an AI faction recruits or replenishes units, the manpower must be paid from the correct population class in the region where the army is located. If the population cannot cover the cost—even after limited, war-only assistance—the unit is removed. No free troops. No magic replenishment.

Alongside this, the mod continues a broader effort to remove AI crutches while maintaining difficulty:

Removing or dialing back AI cheats that bypass population, economy, or logistics.

Phasing out legacy scripted armies (e.g., Punic War stacks) so wars emerge dynamically.

Rebalancing challenge through real constraints (manpower exhaustion, recovery time, class depletion) rather than hidden buffs.

The result is a campaign that is harder, more believable, and more dynamic:
the AI can still field powerful armies—but only if it has the population to sustain them.

## **What’s already changed in this pre-release**

- Removed many game scripts that gave AI stacks, started wars, injected cash into the AI, and more. This is needed to isolate the AI and see where we can build it up. If it ends up not working, we can slowly add features back. But that is a last option.

- AIs are now constrained to population limits, same as the player: every new AI unit must pay its men from the correct class in the current region; if it still comes up short after a small, war-only assist, the unit is removed.

- AI recruitment and replenishment are fully constrained by population.

- Every new AI unit must pay its manpower cost from the correct class.

- Units that cannot be paid for are automatically removed.

- Population losses from recruitment, replenishment, and war now matter long-term.

- Major and minor factions behave differently based on demographic strength.

- Campaigns naturally develop wars of attrition instead of endless stack spam.


## **What’s new in v0.4.1**

## RELEASE — v0.4.1

Divide et Impera - AI Uses Population Overhaul – v0.4.1
Core Fixes

- Fixed AI region population not increasing despite positive growth

- Restored backend population mutation to match UI projections

- Fixed desync between growth calculation and actual population tables

- Prevented silent population stagnation on AI factions

## AI Population Behavior

AI recruitment now:

- Correctly checks population availability

- Deducts population on successful recruitment

- Blocks recruitment when insufficient population exists

- Logs both success and failure states clearly

## AI class promotion:

- Safely redistributes surplus lower-class population upward

- Executes after growth, not before

- Prevents elite-class starvation without creating inflation

## UI & Transparency

- Population Growth panel now reflects real backend data

- Per-class growth numbers match applied population changes

- Total population (white number) updates correctly each turn

- Removed misleading “projection-only” behavior

## Stability & Saves

Fixed zeroing (dy) regression


## Technical Cleanup

Restored 0.3.0’s working growth application logic

Integrated it cleanly into 0.4.0’s expanded systems

Preserved all 0.4.0 features (promotion, AI rules, UI math)

Removed conflicting reset paths and shadow tables


## **Fixes**

- Fixed zeroing (dy) regression

## **Plans for next update**

COntinue to test and balance AI with current feature set. 

=======
- More fine tunign to AI aggression with current mechanics
>>>>>>> Stashed changes

## **Installation**


- Place DEI_AI_Population_MOD_0_4_1_PRE.pack into:

...\Steam\steamapps\common\Total War Rome II\data\


 - In the Mod Manager, enable it **ABOVE ALL** other DEI parts. **IMPORTANT!!!**

Save-game ready, **but a full game restart is preferred after enabling.**

## **Known issues (pre-release)**

- AI can be less aggressiveo n easy mode, recommend normal and above 

## **FOR MODDERS!!**

## A logging script mod is provided (NOT made by me)
- There is a "basic logging script.pack" mod included. If you go into "population.lua" and switch the log activations at the top to "true", logs will be automatically made as you play in your campaign inside your main Rome 2/data folder. Then you can provide them! 

##  **Core enforcement**
## Listeners:
- FactionTurnStart: snapshot each AI army’s unit CQIs.

 - FactionTurnEnd: diff vs. snapshot; unseen unit CQIs are new recruits/refills.

## **Payment Path:**
1. Resolve unit → (class, men) and identify the army’s current region.

2. Try to deduct from region_table[region_key][class_index].

3. If short, call the assist:


## **Blocker**

The removal helper tries, in order:
cm:remove_unit_from_character(char, unit_key) →
cm:remove_unit_from_military_force(mf, unit_key) →
failsafe loop unit:inflict_casualties(unit:number_of_men()) to zero the entity.

## **Script LOGS disabled by default**
 - Script text logs are disabled in this pre-release (you can re-enable for audits).
 

## logging (off in this build)
isLogAllowed = false
isLogPopAllowed = false


## ALL POPULATION CHANGES ARE FOUND IN"population.lua"

## Compatibility & scope

- No global resets of population tables.

- AI-only recruitment enforcement; human recruitment unchanged.

- Save-game compatible (restart preferred after enabling).

