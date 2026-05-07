use bevy::prelude::*;
use kingdom_core::{RegionStates, Tile};

pub fn decay_system(mut tiles: Query<&mut Tile>, region_states: Res<RegionStates>) {
    for mut tile in tiles.iter_mut() {
        if let Some(rid) = tile.region_id {
            let starved = region_states.get(rid).is_none_or(|r| r.sugars <= 0.0);
            if starved {
                tile.biomass -= 0.1;
                if tile.biomass <= 0.0 {
                    tile.biomass = 0.0;
                    tile.region_id = None;
                }
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use kingdom_core::{GridPos, GridWorld, Hex};

    use super::*;

    fn test_app() -> App {
        let mut app = App::new();
        app.add_plugins(MinimalPlugins);
        app.init_resource::<GridWorld>();
        app.init_resource::<RegionStates>();
        app
    }

    #[test]
    fn starved_tile_loses_biomass() {
        let mut app = test_app();
        let mut rs = app.world_mut().resource_mut::<RegionStates>();
        let rid = rs.create_region();
        rs.get_mut(rid).unwrap().sugars = 0.0;

        let entity = app
            .world_mut()
            .spawn((
                GridPos(Hex::ZERO),
                Tile {
                    region_id: Some(rid),
                    biomass: 1.0,
                    ..default()
                },
            ))
            .id();

        app.add_systems(Update, decay_system);
        app.update();

        let tile = app.world().get::<Tile>(entity).unwrap();
        assert!(
            tile.biomass < 1.0,
            "biomass should decay when region is starved"
        );
    }

    #[test]
    fn zero_biomass_tile_reverts_to_empty() {
        let mut app = test_app();
        let mut rs = app.world_mut().resource_mut::<RegionStates>();
        let rid = rs.create_region();
        rs.get_mut(rid).unwrap().sugars = 0.0;

        let entity = app
            .world_mut()
            .spawn((
                GridPos(Hex::ZERO),
                Tile {
                    region_id: Some(rid),
                    biomass: 0.05,
                    ..default()
                },
            ))
            .id();

        app.add_systems(Update, decay_system);
        app.update();

        let tile = app.world().get::<Tile>(entity).unwrap();
        assert_eq!(
            tile.region_id, None,
            "tile should revert to empty at zero biomass"
        );
    }
}
