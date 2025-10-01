import { useState } from 'react'
import './App.css'
import DragAndDrop from './iframe'

function App() {
  const [count, setCount] = useState(0)

  return (
    <>
      <DragAndDrop />
    </>
  )
}

export default App
