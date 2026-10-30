
var castForgeProgress = {}

BlockEvents.rightClicked(event => {
    if (event.level.isClientSide()) return
    if (event.block.id != 'create:depot') return
    if (event.item.id != 'ftbstuff:netherite_hammer') return

    var castTile = event.block.entity

    if (castTile) {
        var castHeld = castTile.getHeldItem()

        if (!castHeld.isEmpty() &&
            castHeld.id == 'ftbstuff:cast_iron_ingot') {

            var castPos = event.block.pos
            var castKey = String(event.level.dimension) + ':' +
                castPos.x + ':' + castPos.y + ':' + castPos.z

            var castState = castForgeProgress[castKey]

            if (!castState) {
                castState = {
                    hits: 0,
                    lastHit: 0
                }
                castForgeProgress[castKey] = castState
            }

            var castNow = Date.now()

            // 100ms cooldown between hammer strikes
            if (castNow - castState.lastHit >= 100) {
                castState.lastHit = castNow
                castState.hits++

                // Play anvil sound on each valid strike
                event.server.runCommandSilent(
                    'execute as ' + event.player.username +
                    ' at @s run playsound minecraft:block.anvil.use block @s ~ ~ ~ 1 1'
                )

                // Consume 1 durability point
                // for each valid hammer strike
                var castHammerItem = event.item

                if (!event.player.creative &&
                    castHammerItem.getMaxDamage() > 0) {

                    var castNewDamage =
                        castHammerItem.getDamageValue() + 1

                    if (castNewDamage >= castHammerItem.getMaxDamage()) {
                        // The hammer breaks
                        castHammerItem.count = 0

                        event.server.runCommandSilent(
                            'execute as ' + event.player.username +
                            ' at @s run playsound minecraft:entity.item.break player @s ~ ~ ~ 1 1'
                        )
                    } else {
                        castHammerItem.setDamageValue(castNewDamage)
                    }
                }

                // Visual progress bar: 5 steps
                var castBar = ''

                for (var castI = 0; castI < 5; castI++) {
                    castBar += castI < castState.hits ?
                        '§a▰' : '§7▱'
                }

                // Display progress bar above the hotbar
                event.server.runCommandSilent(
                    'title ' + event.player.username +
                    ' actionbar {"text":"§6🔨 Forging  §r' +
                    castBar + ' §f' + castState.hits + '/5"}'
                )

                console.info(
                    '[FORGE] Strike ' + castState.hits + '/5'
                )

                // Convert the ingot on the fifth strike
                if (castState.hits >= 5) {
                    var castRemaining = castHeld.count - 1

                    if (castRemaining > 0) {
                        castTile.setHeldItem(
                            Item.of(
                                'ftbstuff:cast_iron_ingot',
                                castRemaining
                            )
                        )
                    } else {
                        castTile.setHeldItem(Item.empty)
                    }

                    castTile.setChanged()
                    castTile.notifyUpdate()

                    // Give exactly 1 Iron Ingot to the player
                    event.player.give(
                        Item.of('minecraft:iron_ingot', 1)
                    )

                    // Reset progress for the next ingot
                    castState.hits = 0

                    console.info('[FORGE] Iron Ingot produced')
                }
            }
        }
    }

    // IMPORTANT: Keep this as the last statement.
    // event.cancel() immediately exits the event in KubeJS.
    event.cancel()
})
