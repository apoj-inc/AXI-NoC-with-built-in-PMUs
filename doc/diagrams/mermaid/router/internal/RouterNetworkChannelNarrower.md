```mermaid
flowchart LR
    subgraph NAR["for i < min(WIDTH_IN, WIDTH_OUT)"]
        direction LR
        SI["s_axis_i[i]"] --> MO["m_axis_o[i]"]
    end
```