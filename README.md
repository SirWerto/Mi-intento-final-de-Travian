# MyTravian

MyTravian will be a platform for analyzing [Travian](https://www.travian.com)'s data with machine learning algorithms.

The project born during my master's thesis and I am still pushing the idea.

## Roadmap for the Beta
    [x] Collector for fetching the data
    [x] Storage system
    [] Medusa for player predictions
    [] Satellite tables for pushing the data to the front
    [] Front for showing the results

## Arch Overview

The platform is divided in serveral Erlang style applications and it drives itself using events.

Apps:
- [Collector](/apps/collector/README.md)
- [Medusa](/apps/medusa/README.md)
- [Satellite](/apps/satellite/README.md)
- [Front](/apps/front/README.md)


![MyTrvian Arch](/imgs/mytravian_arch.png)
