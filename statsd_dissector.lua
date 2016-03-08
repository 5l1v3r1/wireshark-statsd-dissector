local statsd = Proto("statsd","Statsd Protocol")

local pf_metric_name = ProtoField.new("Metric Name", "statsd.metric_name", ftypes.STRING)
local pf_value = ProtoField.new("Value", "statsd.value", ftypes.STRING)
local pf_metric_type = ProtoField.new("Metric Type", "statsd.metric_type", ftypes.STRING)
local pf_sample_rate = ProtoField.new("Sample Rate", "statsd.sample_rate", ftypes.STRING)
local pf_dogstatsd_tag = ProtoField.new("Tag", "statsd.dogstatsd.tag", ftypes.STRING)

statsd.fields = { pf_metric_name, pf_value, pf_metric_type, pf_sample_rate, pf_dogstatsd_tag }

function statsd.dissector(tvbuf,pktinfo,root)
  local pktlen = tvbuf:reported_length_remaining()
  local tvbr = tvbuf:range(0,pktlen)

  -- <metric name>:<value>|<metric type>[|@<sample rate>]
  local payload = tvbr:string()
  local a, b, metric_name, value, metric_type, extra = string.find(payload, "^([^:]+):([^|]+)|([^|]+)(.*)")

  if a then
    pktinfo.cols.protocol:set("Statsd")
    pktinfo.cols.info:set(payload)

    local pos = 0
    local tree = root:add(statsd, tvbr)

    tree:add(pf_metric_name, tvbuf:range(pos, metric_name:len()), metric_name)
    pos = pos + metric_name:len() + 1

    tree:add(pf_value, tvbuf:range(pos, value:len()), value)
    pos = pos + value:len() + 1

    tree:add(pf_metric_type, tvbuf:range(pos, metric_type:len()), metric_type)
    pos = pos + metric_type:len()

    repeat
      local c, d, marker, body = string.find(extra, "^|(.)([^|]+)")
      if c then
        pos = pos + 2
        if marker == "@" then
          tree:add(pf_sample_rate, tvbuf:range(pos, body:len()), body)
          pos = pos + body:len()
        end
        if marker == "#" then
          local tags_tree = tree:add("Dogstatsd Tags")
          repeat
            local e, f, tag = string.find(body, "^([^,]+),?")
            if e then
              tags_tree:add(pf_dogstatsd_tag, tvbuf:range(pos, tag:len()), tag)
              pos = pos + f
              body = string.sub(body, f + 1, -1)
            end
          until e == nil
        end
        extra = string.sub(extra, d + 1, -1)
      end
    until c == nil
  end
end

DissectorTable.get("udp.port"):add(8125, statsd)
