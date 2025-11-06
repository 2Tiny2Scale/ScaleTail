# Tandoor Recipes with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [**Tandoor Recipes**](https://github.com/TandoorRecipes/recipes) with Tailscale as a sidecar container, which enables a secure access to your personal recipe and meal planning platform from your Tailscale network. As with all other services inside this repository, your service stays fully private and accessible only to your authorized devices.

## Tandoor Recipes

[**Tandoor Recipes**](https://github.com/TandoorRecipes/recipes) is an application for managing recipes, planning meals, building shopping lists and much much more:

- 🥗 **Manage your recipes** - Manage your ever growing recipe collection
- 📆 **Plan** - multiple meals for each day
- 🛒 **Shopping lists** - via the meal plan or straight from recipes
- 🪄 **use AI** to recognize images, sort recipe steps, find nutrition facts and more
- 📚 **Cookbooks** - collect recipes into books
- 👪 **Share and collaborate** on recipes with friends and family

## Configuration Overview

In this setup, the `tailscale-tandoor` service runs Tailscale, which manages secure networking for the service. The `tandoor` service utilizes the Tailscale network stack via Docker's `network_mode: service:tailscale-tandoor` configuration. This setup ensures that tandoor's service is only accessible through the Tailscale network (or locally, if preferred), providing an extra layer of security and privacy for your service.
