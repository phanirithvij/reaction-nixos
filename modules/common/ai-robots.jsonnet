// https://reaction.ppom.me/filters/ai-crawlers.html
local aiRobots = import "@ai_robots_json@";
local names = std.objectFields(aiRobots);

local joined = std.join("|", names);
local regex =  @'^<ip>.*"[^"]*(' + joined + ')[^"]*"$';

local actions = @actions@;

{
  streams: {
    nginx: {
      filters: {
        gptbot: {
          regex: [ regex ],
          actions: actions,
        }
      }
    }
  }
}

