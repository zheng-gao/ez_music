import React from "react";
import "../css/App.css";
import MaterialTable from "material-table";

class App extends React.Component {
    constructor(props) {
        super(props);
        this.state = {isLoading: true, users: null};
    }

    async componentDidMount() {
        const response = await fetch("/api/user/all");
        const body = await response.json();
        this.setState({isLoading: false, users: body});
    }

    render() {
        if (this.state.isLoading) return <p>Loading...</p>;
        // https://github.com/mbrn/material-table
        const columnsDef = [
            { title: "ID", field: "id" },
            { title: "First Name", field: "firstName" },
            { title: "Last Name", field: "lastName" },
            { title: "Email", field: "email" }
        ];
        return (
            <div className="App">
                <header className="App-header">
                    <div className="App-intro">
                        <MaterialTable columns={columnsDef} data={this.state.users} title="Users"/>
                    </div>
                </header>
            </div>
        );
    }
}

export default App;
