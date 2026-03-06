# ClawBee — Full Command Reference

## Orchestrator
| Command | Description |
|---------|-------------|
| `/plan weekly [budget]` | Full pipeline (fridge + prices + plan + Telegram) |
| `/plan status` | Check system status |
| `/plan post` | Post plan to Discord |
| `/plan help` | Show this reference |

## Fridge Tracker
| Command | Description |
|---------|-------------|
| `/fridge list` | Show current contents |
| `/fridge add <item> [qty]` | Add item to fridge |
| `/fridge remove <item>` | Remove item |
| `/fridge clear` | Clear all contents |

## Fridge Scanner
| Command | Description |
|---------|-------------|
| `/scan` + photo | Scan photo → instant 3-day plan |
| `/scan demo` | Demo mode (no photo needed) |
| `/scan plan` | Show last scan plan |
| `/scan shop` | Send scan's shopping list to Telegram |

## Meal Planner
| Command | Description |
|---------|-------------|
| `/meals plan [budget]` | Generate weekly plan |
| `/meals show` | Show current plan |
| `/meals pref <key> <value>` | Set preference (people, vegetarian, budget) |

## Price Hunter
| Command | Description |
|---------|-------------|
| `/prices search <item>` | Find cheapest price in Berlin |
| `/prices best <item>` | Show best known price |
| `/prices list` | All tracked prices |

## Shopping Agent
| Command | Description |
|---------|-------------|
| `/shopping list` | View optimized shopping list |
| `/shopping send` | Send to Telegram |
| `/shopping optimize [€]` | Check against budget |
