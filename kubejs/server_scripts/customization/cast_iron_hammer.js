
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

            // Cooldown de 100ms entre marteladas
            if (castNow - castState.lastHit >= 100) {
                castState.lastHit = castNow
                castState.hits++

                // Som de bigorna em cada martelada
                event.server.runCommandSilent(
                    'execute as ' + event.player.username +
                    ' at @s run playsound minecraft:block.anvil.use block @s ~ ~ ~ 1 1'
                )

                // Gasta 1 ponto de durabilidade
                // a cada martelada valida
                var castHammerItem = event.item

                if (!event.player.creative &&
                    castHammerItem.getMaxDamage() > 0) {

                    var castNewDamage =
                        castHammerItem.getDamageValue() + 1

                    if (castNewDamage >= castHammerItem.getMaxDamage()) {
                        // O martelo quebrou
                        castHammerItem.count = 0

                        event.server.runCommandSilent(
                            'execute as ' + event.player.username +
                            ' at @s run playsound minecraft:entity.item.break player @s ~ ~ ~ 1 1'
                        )
                    } else {
                        castHammerItem.setDamageValue(castNewDamage)
                    }
                }

                // Barra visual: 5 etapas
                var castBar = ''

                for (var castI = 0; castI < 5; castI++) {
                    castBar += castI < castState.hits ?
                        '§a▰' : '§7▱'
                }

                // Mostra a barra acima da hotbar
                event.server.runCommandSilent(
                    'title ' + event.player.username +
                    ' actionbar {"text":"§6🔨 Forjando  §r' +
                    castBar + ' §f' + castState.hits + '/5"}'
                )

                console.info(
                    '[FORJA] Batida ' + castState.hits + '/5'
                )

                // Transformacao na quinta batida
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

                    // Entrega exatamente 1 Iron Ingot
                    event.player.give(
                        Item.of('minecraft:iron_ingot', 1)
                    )

                    // Reinicia para o proximo lingote
                    castState.hits = 0

                    console.info('[FORJA] Iron Ingot produzido')
                }
            }
        }
    }

    // IMPORTANTE: ultima instrucao.
    // event.cancel() encerra a execucao no KubeJS.
    event.cancel()
})
