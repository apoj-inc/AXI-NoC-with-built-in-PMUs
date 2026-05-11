```mermaid
flowchart LR
    subgraph MAP["for each allocated_channel"]
        direction LR
        SI["s_axis_i[allocated_channel]"] --> MO["m_axis_o[allocated_channel]"]
    end
```