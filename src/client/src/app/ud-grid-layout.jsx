import React from 'react';
import { WidthProvider, Responsive } from "react-grid-layout";
const ResponsiveReactGridLayout = WidthProvider(Responsive);

require('react-grid-layout/css/styles.css');
require('react-resizable/css/styles.css');

export default class UDGridLayout extends React.Component {

    constructor(props) {
        super(props);

        var layouts = null;
        if (props.layout) {
          layouts = JSON.parse(props.layout)

          if (!Array.isArray) {
            layouts = []
          } else {
            saveToLS("uddesign", layouts)
          }

        } 

        if (props.persist) {
            var jsonLayouts = getFromLS("layouts");
            if (jsonLayouts != null) {
                layouts = JSON.parse(JSON.stringify(jsonLayouts))
            }
        };

        if (UniversalDashboard.design) {
            var jsonLayouts = getFromLS("uddesign");
            if (jsonLayouts != null) {
                layouts = JSON.parse(JSON.stringify(jsonLayouts))

                if (layouts.lg != null) {
                  layouts.lg.forEach(x => {
                    x.static = false
                  });
                }
            }
        }

        this.state = {
            layouts, 
            content: props.content
        };
    }

    onLayoutChange(layout, layouts) {
      if (this.props.persist) {
          saveToLS("layouts", layouts);
          this.setState({ layouts });
      }

      if (UniversalDashboard.design) {
          saveToLS("uddesign", layouts);
          this.setState({ layouts });
      }
    }

    render() {
        var elements = this.state.content.map(x => 
                <div key={"grid-element-" + x.id}>
                    {UniversalDashboard.renderComponent(x)}
                </div>
            );

        return (
            <ResponsiveReactGridLayout className={this.props.className} layouts={this.state.layouts} cols={this.props.cols} rowHeight={this.props.rowHeight}  onLayoutChange={this.onLayoutChange.bind(this)}>
                {elements}
            </ResponsiveReactGridLayout>
        )
    }
}

function getFromLS(key) {
    let ls = {};
    if (global.localStorage) {
      try {
        ls = JSON.parse(global.localStorage.getItem("rgl-8")) || {};
      } catch (e) {
        /*Ignore*/
      }
    }
    return ls[key];
  }
  
  function saveToLS(key, value) {
    if (global.localStorage) {
      global.localStorage.setItem(
        "rgl-8",
        JSON.stringify({
          [key]: value
        })
      );
    }
  }