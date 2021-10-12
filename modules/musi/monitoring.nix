{ config, pkgs, ... }:

{
  services.vnstat.enable = true;

  environment.etc."vnstat.conf".text = ''
    Interface enp6s0

    # Daemon

    BandwithDetection 1

    PollInterval 5

    TrafficlessEntries 1
    TopDayEntries 0

    5MinutesHours 168
    HourlyDays -1
    DailyDays -1
    MonthlyMonths -1
    YearlyYears -1

    # Output
  '';

  # Cron jobs
  services.cron = {
    enable = true;
    systemCronJobs = [
      ''* * * * *      ppom    ${config.users.users.ppom.home}/bin/check_co.sh''
    ];
  };
}

