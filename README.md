# Shoes-Mail-Client

This sample will show you to create a Mail Box using the Nylas APIs, JRuby and Shoes 4.

Let's celebrate _why's Day on August 19.

## Setup

### System dependencies

- Java 9.0.4.0.11
- JRuby-9.3.4.0

### Gather environment variables

You'll need the following values:

```text
ACCESS_TOKEN = ""
```

Add the above values to a new `.env` file:

```bash
$ touch .env # Then add your env variables
```

### Install dependencies

```bash
# To read .env files
$ gem install dotenv

# Makes http fun again
$ gem install httparty

# Shoes 4 GUI Toolkit
$ gem install shoes --pre

```

## Usage

Run the app using the `shoes` command:

```bash
$ shoes Shoes_Mail_Client.rb
```

When successfull, it will display a GUI window showing the first 5 emails from the inbox.

## Read the blog post
[_why day 2022](https://www.nylas.com/blog/_why-day-2022-dev/)

## Learn more

Visit our [Nylas Email API documentation](https://developer.nylas.com/docs/connectivity/email/) to learn more.
