/** @jsx React.DOM */

var ResultTable = React.createClass({
  render: function() {
    var tableClass = React.addons.classSet({
      "hidden": this.props.hidden
    })

    return (
      <div className={tableClass}>
        <div className="row">
          <div className="two-thirds column heading">Word</div>
          <div className="one-third column heading">Nearest</div>
        </div>
        {this.props.data.map(function(row) {
          return (
          <div className="row">
            <div className="two-thirds column">
              <a href="#" onClick={function(){ this.props.onQuery(row[0]) }.bind(this)}>{row[0]}</a>
            </div>
            <div className="one-third column">
              {row[1].toFixed(3)}
            </div>
          </div>
          )
        }.bind(this))}
      </div>
    )
  }
})
