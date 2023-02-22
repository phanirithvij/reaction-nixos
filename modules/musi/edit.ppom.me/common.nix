{}:
{
  mailSettings = {
    EMAIL_FROM = "directus@ppom.me";
    EMAIL_TRANSPORT = "smtp";
    EMAIL_SMTP_HOST = "mail.ppom.me";
    EMAIL_SMTP_PORT = 465;
    EMAIL_SMTP_SECURE = true;
    EMAIL_SMTP_USER = "postmaster@ppom.me";
    EMAIL_SMTP_PASSWORD_FILE = "/var/secrets/mail/postmaster"; # Must not end with a newline
  };

  sshKey = "/var/secrets/pompeani.art/key";
}
