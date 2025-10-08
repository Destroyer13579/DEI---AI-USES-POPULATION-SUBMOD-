# **DEI SubMod: AI USES POPULATION AND MORE v0.3.0 — PRE-RELEASE** 

 Status: Experimental, but working in testing. Save-game ready (restart preferred).

### **What this mod does**

This pre-release makes the AI follow the same population constraints as the player, among other changes. When an AI faction recruits, the unit must be “paid for” out of the correct population class in the region where that army currently stands. If the region can’t cover the cost (even after a small, wartime-only assist), the unit is removed. No magic troops.

In parallel, this build continues a broader effort to strip AI crutches while keeping difficulty:

Removing or dialing back AI cheats/bonuses that bypass population, economy, or movement.

Phasing out certain scripted armies (e.g., legacy Punic War stacks) so wars emerge from a dynamic world, not hard scripts.

Rebalancing pressure through realistic constraints (recruitment affordability, recovery time, class exhaustion) rather than hidden buffs.

The result is a campaign that’s more difficult and more believable: the AI can still field strong forces, but it must do so within population and logistics—just like you.

## **How the new AI population system works (simple)**

- Spot new AI units: We take a snapshot at the start of an AI faction’s turn and compare at the end. Anything new is a recruit/top-up.

- Charge the cost: We look up the unit’s population class and men cost, and try to pay it from that region’s pool for the same class.

**If short:**

- Borrow the same class from other regions in the same province (small amounts).

- If the faction is at war, add a small emergency levy (never for elites) to finish the bill.

- If the cost still can’t be covered: The unit is deleted.

- **No class mixing**: Citizens cannot be made from freemen, etc. Humans are unaffected.

- In practice: when upper-class pools are drained, elites fail to recruit; the AI fields what it can actually afford, especially during wars. In peacetime, levies are disabled.

## **What’s already changed in this pre-release**

- Removed many game scripts that gave AI stacks, started wars, injected cash into the AI, and more. This is needed to isolate the AI and see where we can build it up. If it ends up not working, we can slowly add features back. But that is a last option.

- AIs are now constrained to population limits, same as the player: every new AI unit must pay its men from the correct class in the current region; if it still comes up short after a small, war-only assist, the unit is removed.


## **What’s new in v0.3.0**

- AI “pay-or-delete” recruitment

- At AI turn end, any newly appeared unit (or large refill) must be paid from the region’s population pool for that unit’s class. If payment fails, the unit is deleted.

- Gentle assist, war-only
If the region is slightly short, the AI may (a) siphon the same class from other regions in the same province, and then (b) apply a small emergency levy only while at war.
Citizens/Elites are never levied. Default caps in this build:

-- 1..4 = citizen, freemen, lower, foreigners
LEVY_MAX = { [1]=0, [2]=40, [3]=60, [4]=40 }
WAR_ONLY = true


## **Fixes**
- Fixed a long-standing issue where Rome and Carthage remained friendly for the entire campaign instead of drifting into hostility and war. They are now pushed back to war more easily like default DEI. 
- Fixed the main folder "3.0" to "0.3.0"

## **Plan for next update:**
- AI aggresion targeted-tweaks to lesson passive tendencies. (NO TABLE TUNING)
- Population growth tweaks for AI
- AI levy system changes 
  
## **Script LOGS disabled by default**
 - Script text logs are disabled in this pre-release (you can re-enable for audits).

## **Installation**

- Place DEI_AI_Pop_MOD_0_3_0_PRE.pack into:

...\Steam\steamapps\common\Total War Rome II\data\


 - In the Mod Manager, enable it **ABOVE ALL** other DEI parts. **IMPORTANT!!!**

Save-game ready, **but a full game restart is preferred after enabling.**

## **Known issues (pre-release)**

## - **Occasional AI passivity**
Some factions can be too passive under the new constraints. A targeted adjustment is in progress for a future update.

## - **Cheat removal, work-in-progress**
AI crutches (notably scripted Punic War armies) are being removed to keep the experience “difficult, realistic, vanilla.” Side effects remain; e.g., Sicily tension notifications may trigger prematurely for Rome and Carthage.

## - **Extreme depletion during major wars**
You may see severely drained AI population numbers after large wars. This is expected with the new rules but not fully balanced; next steps for AI population replenishment are under review.

## **FOR MODDERS!!**

##  **Core enforcement**
## Listeners:
- FactionTurnStart: snapshot each AI army’s unit CQIs.

 - FactionTurnEnd: diff vs. snapshot; unseen unit CQIs are new recruits/refills.

## **Payment Path:**
1. Resolve unit → (class, men) and identify the army’s current region.

2. Try to deduct from region_table[region_key][class_index].

3. If short, call the assist:

## Siphon: same class, same province, small amounts (respecting donor safety if configured).

Levy: only if WAR_ONLY and the faction is at war; add up to LEVY_MAX[class] to bridge the remainder (Citizens/Elites have cap 0).

4. If coverage succeeds, deduct full cost from the target region and keep the unit; otherwise, remove it.

## **Blocker**

The removal helper tries, in order:
cm:remove_unit_from_character(char, unit_key) →
cm:remove_unit_from_military_force(mf, unit_key) →
failsafe loop unit:inflict_casualties(unit:number_of_men()) to zero the entity.


# **Defaults in v0.3.0 PRE-RELEASE**
## assistance
SIPHON_FROM_SAME_PROVINCE = true
WAR_ONLY = true
LEVY_MAX = { [1]=0, [2]=40, [3]=60, [4]=40 }

## logging (off in this build)
isLogAllowed = false
isLogPopAllowed = false


## ALL POPULATION CHANGES ARE FOUND IN"population.lua"

## Compatibility & scope

- No changes to UI projections, growth math, or divisors.

- No global resets of population tables.

- AI-only recruitment enforcement; human recruitment unchanged.

- Save-game compatible (restart preferred after enabling).

**If you need a variant with different levy caps, province reserve floors, or per-turn levy limits, open an issue with your preferred values for a follow-up build.**
