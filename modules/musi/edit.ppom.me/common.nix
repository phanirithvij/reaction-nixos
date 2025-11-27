{ }:
{
  settings = {
    EMAIL_FROM = "edit@ppom.fr";
    EMAIL_TRANSPORT = "smtp";
    EMAIL_SMTP_HOST = "mail.girofle.org";
    EMAIL_SMTP_PORT = 465;
    EMAIL_SMTP_SECURE = true;
    EMAIL_SMTP_USER = "edit@ppom.fr";
    EMAIL_SMTP_PASSWORD_FILE = "/var/secrets/mail/edit@ppom.fr"; # Must not end with a newline

    LOG_LEVEL = "warn";

    # Defaults to denying localhost
    IMPORT_IP_DENY_LIST = "";
  };

  sshKey = "/var/secrets/akesi/key";
}
