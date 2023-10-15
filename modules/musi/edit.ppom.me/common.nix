{}:
{
  settings = {
    # EMAIL_FROM = "directus@ppom.me";
    # EMAIL_TRANSPORT = "smtp";
    # EMAIL_SMTP_HOST = "smtp.ecomail.fr";
    # EMAIL_SMTP_PORT = 465;
    # EMAIL_SMTP_SECURE = true;
    # EMAIL_SMTP_USER = "paco@ecomail.io";
    # EMAIL_SMTP_PASSWORD_FILE = "/var/secrets/mail/ecomail"; # Must not end with a newline

    LOG_LEVEL = "warn";

    # Defaults to denying localhost
    IMPORT_IP_DENY_LIST = "";
  };

  sshKey = "/var/secrets/akesi/key";
}
