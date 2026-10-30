
JEIAddedEvents.registerCategories(event => {
    var gui = event.JEI_HELPERS.guiHelper

    event.custom("skycore:manual_hammering", category => {
        category
            .title("Martelagem Manual")
            .background(gui.createBlankDrawable(145, 75))
            .icon(
                gui.createDrawableItemStack(
                    Item.of("ftbstuff:netherite_hammer")
                )
            )
            .isRecipeHandled(recipe => {
                return recipe != null
            })
            .handleLookup((builder, recipe, focuses) => {
                builder.addSlot("INPUT", 8, 12)
                    .addItemStack(
                        Item.of("ftbstuff:cast_iron_ingot")
                    )

                builder.addSlot("INPUT", 36, 12)
                    .addItemStack(
                        Item.of("ftbstuff:netherite_hammer")
                    )

                builder.addSlot("OUTPUT", 105, 12)
                    .addItemStack(
                        Item.of("minecraft:iron_ingot")
                    )
            })
            .setDrawHandler((recipe, slots, graphics, mx, my) => {
                graphics.drawWordWrap(
                    Client.font,
                    Text.of("Depot + Netherite Hammer"),
                    5, 42, 130, 0xFFFFFF
                )

                graphics.drawWordWrap(
                    Client.font,
                    Text.of("5 marteladas manuais"),
                    5, 55, 130, 0xAAAAAA
                )
            })
    })
})

JEIAddedEvents.registerRecipes(event => {
    event.custom("skycore:manual_hammering")
        .add({
            input: "ftbstuff:cast_iron_ingot",
            tool: "ftbstuff:netherite_hammer",
            output: "minecraft:iron_ingot",
            hits: 5
        })
})
