# Install Medusa

In this chapter, you'll learn how to install and run a Medusa application.

## Create Medusa Application

A Medusa application is made up of a Node.js server and an admin dashboard. You can optionally install the [Next.js Starter Storefront](https://docs.medusajs.com/resources/nextjs-starter) separately either while installing the Medusa application or at a later point.

While this is the recommended way to create a Medusa application, you can alternatively [install a Medusa application with Docker](https://docs.medusajs.com/learn/installation/docker).

### Prerequisites

- [Node.js v20+](https://nodejs.org/en/download)
- [Git CLI tool](https://git-scm.com/downloads)
- [PostgreSQL](https://www.postgresql.org/download/)

To create a Medusa application, use the `create-medusa-app` command:

```bash
npx create-medusa-app@latest my-medusa-store
```

Where `my-medusa-store` is the name of the project's directory and PostgreSQL database created for the project. When you run the command, you'll be asked whether you want to install the Next.js Starter Storefront.

To customize the default installation behavior, such as specify a database URL, refer to the [create-medusa-app reference](https://docs.medusajs.com/resources/create-medusa-app).

After answering the prompts, the command installs the Medusa application in a directory with your project name, and sets up a PostgreSQL database that the application connects to.

If you chose to install the storefront with the Medusa application, the storefront is installed in a separate directory named `{project-name}-storefront`.

![Directory structure overview after Medusa installation showing the main project folder containing the Medusa backend application and admin dashboard, alongside the separate storefront directory for the customer-facing Next.js application](https://res.cloudinary.com/dza7lstvk/image/upload/v1745856132/Medusa%20Resources/installation-dirs_x8jux4.jpg)

### Successful Installation Result

Once the installation finishes successfully, the Medusa application will run at `http://localhost:9000`.

The Medusa Admin dashboard also runs at `http://localhost:9000/app`. The installation process opens the Medusa Admin dashboard in your default browser to create a user. You can later log in with that user.

If you also installed the Next.js Starter Storefront, it'll be running at `http://localhost:8000`.

You can stop the servers for the Medusa application and Next.js Starter Storefront by exiting the installation command. To run the server for the Medusa application again, refer to [this section](#run-medusa-application-in-development).

![Post-installation running services overview: Medusa backend server and admin dashboard running on localhost:9000, Next.js Starter Storefront running on localhost:8000, with PostgreSQL database and other essential services active and ready for development](https://res.cloudinary.com/dza7lstvk/image/upload/v1745856706/Medusa%20Resources/success-overview_bj4pbt.jpg)

### Troubleshooting Installation Errors

If you ran into an error during your installation, refer to the following troubleshooting guides for help:

1. [create-medusa-app troubleshooting guides](https://docs.medusajs.com/resources/troubleshooting/create-medusa-app-errors).
2. [CORS errors](https://docs.medusajs.com/resources/troubleshooting/cors-errors).
3. [Errors with pnpm](https://docs.medusajs.com/resources/troubleshooting/pnpm).
4. [All troubleshooting guides](https://docs.medusajs.com/resources/troubleshooting).

If you can't find your error reported anywhere, please open a [GitHub issue](https://github.com/medusajs/medusa/issues/new/choose).

***

## Run Medusa Application in Development

To run the Medusa application in development, change to your application's directory and run the following command:

```bash npm2yarn
npm run dev
```

This runs your Medusa server at `http://localhost:9000`, and the Medusa Admin dashboard `http://localhost:9000/app`.

![Diagram showcasing the server and application running when you start the Medusa application](https://res.cloudinary.com/dza7lstvk/image/upload/v1745856966/Medusa%20Resources/start-overview_aetplx.jpg)

For details on starting and configuring the Next.js Starter Storefront, refer to [this documentation](https://docs.medusajs.com/resources/nextjs-starter).

The application will restart if you make any changes to code under the `src` directory, except for admin customizations which are hot reloaded, providing you with a seamless developer experience without having to refresh your browser to see the changes.

***

## Create Medusa Admin User

Aside from creating an admin user in the admin dashboard, you can create a user with Medusa's CLI tool.

Run the following command in your Medusa application's directory to create a new admin user:

```bash
npx medusa user -e admin@medusajs.com -p supersecret
```

Replace `admin@medusajs.com` and `supersecret` with the user's email and password respectively.

You can then use the user's credentials to log into the Medusa Admin application.

***

## Project Files

Your Medusa application's project will have the following files and directories:

![A diagram of the directories overview](https://res.cloudinary.com/dza7lstvk/image/upload/v1732803813/Medusa%20Book/medusa-dir-overview_v7ks0j.jpg)

### src

This directory is the central place for your custom development. It includes the following sub-directories:

- `admin`: Holds your admin dashboard's custom [widgets](https://docs.medusajs.com/learn/fundamentals/admin/widgets) and [UI routes](https://docs.medusajs.com/learn/fundamentals/admin/ui-routes).
- `api`: Holds your custom [API routes](https://docs.medusajs.com/learn/fundamentals/api-routes) that are added as endpoints in your Medusa application.
- `jobs`: Holds your [scheduled jobs](https://docs.medusajs.com/learn/fundamentals/scheduled-jobs) that run at a specified interval during your Medusa application's runtime.
- `links`: Holds your [module links](https://docs.medusajs.com/learn/fundamentals/module-links) that build associations between data models of different modules.
- `modules`: Holds your custom [modules](https://docs.medusajs.com/learn/fundamentals/modules) that implement custom business logic.
- `scripts`: Holds your custom [scripts](https://docs.medusajs.com/learn/fundamentals/custom-cli-scripts) to be executed using Medusa's CLI tool.
- `subscribers`: Holds your [event listeners](https://docs.medusajs.com/learn/fundamentals/events-and-subscribers) that are executed asynchronously whenever an event is emitted.
- `workflows`: Holds your custom [flows](https://docs.medusajs.com/learn/fundamentals/workflows) that can be executed from anywhere in your application.

### medusa-config.ts

This file holds your [Medusa configurations](https://docs.medusajs.com/learn/configurations/medusa-config), such as your PostgreSQL database configurations.

### .medusa

The `.medusa` directory holds types and other files that are generated by Medusa when you run the `build` command. Don't modify any files or commit them to your repository.

***

## Configure Medusa Application

By default, your Medusa application is equipped with the basic configuration to start your development.

If you run into issues with configurations, such as CORS configurations, or need to make changes to the default configuration, refer to [this guide on all available configurations](https://docs.medusajs.com/learn/configurations/medusa-config).

***

## Update Medusa Application

Refer to [this documentation](https://docs.medusajs.com/learn/update) to learn how to update your Medusa project.

***

## Next Steps

In the next chapters, you'll learn about the architecture of your Medusa application, then learn how to customize your application to build custom features.