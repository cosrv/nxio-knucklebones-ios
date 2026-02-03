import React, { useState, useCallback, useEffect, useRef } from 'react';

const GRID_SIZE = 3;

// Crypto-secure random dice roll
const rollDice = () => {
  const array = new Uint32Array(1);
  crypto.getRandomValues(array);
  return (array[0] % 6) + 1;
};

function Knucklebones() {
  const [playerGrid, setPlayerGrid] = useState(Array(3).fill(null).map(() => Array(3).fill(null)));
  const [opponentGrid, setOpponentGrid] = useState(Array(3).fill(null).map(() => Array(3).fill(null)));
  const [currentDice, setCurrentDice] = useState(null);
  const [displayDice, setDisplayDice] = useState(null); // What's shown during animation
  const [isPlayerTurn, setIsPlayerTurn] = useState(true);
  const [gameOver, setGameOver] = useState(false);
  const [winner, setWinner] = useState(null);
  const [isRolling, setIsRolling] = useState(false);
  const rollIntervalRef = useRef(null);

  const calculateColumnScore = (column) => {
    const values = column.filter(v => v !== null);
    const counts = {};
    values.forEach(v => { counts[v] = (counts[v] || 0) + 1; });
    let score = 0;
    values.forEach(v => { score += v * counts[v]; });
    return score;
  };

  const calculateTotalScore = (grid) => {
    return grid.reduce((total, col) => total + calculateColumnScore(col), 0);
  };

  const isGridFull = (grid) => {
    return grid.every(col => col.every(cell => cell !== null));
  };

  const getAvailableColumns = (grid) => {
    return grid.map((col, idx) => col.some(cell => cell === null) ? idx : -1)
               .filter(idx => idx !== -1);
  };

  const placeDice = useCallback((grid, colIndex, value) => {
    const newGrid = grid.map(col => [...col]);
    const col = newGrid[colIndex];
    const emptyIndex = col.findIndex(cell => cell === null);
    if (emptyIndex !== -1) {
      col[emptyIndex] = value;
    }
    return newGrid;
  }, []);

  const removeMatchingDice = useCallback((grid, colIndex, value) => {
    const newGrid = grid.map(col => [...col]);
    const col = newGrid[colIndex];
    const filtered = col.filter(cell => cell !== value);
    while (filtered.length < GRID_SIZE) {
      filtered.push(null);
    }
    newGrid[colIndex] = filtered;
    return newGrid;
  }, []);

  const checkGameOver = useCallback((pGrid, oGrid) => {
    if (isGridFull(pGrid) || isGridFull(oGrid)) {
      setGameOver(true);
      const playerScore = calculateTotalScore(pGrid);
      const opponentScore = calculateTotalScore(oGrid);
      if (playerScore > opponentScore) setWinner('player');
      else if (opponentScore > playerScore) setWinner('opponent');
      else setWinner('tie');
      return true;
    }
    return false;
  }, []);

  // Animated dice roll with crypto entropy
  const animateRoll = useCallback((onComplete) => {
    setIsRolling(true);
    const finalValue = rollDice();
    let ticks = 0;
    const maxTicks = 10 + (rollDice() % 5); // Random number of animation frames
    
    // Clear any existing interval
    if (rollIntervalRef.current) {
      clearInterval(rollIntervalRef.current);
    }
    
    rollIntervalRef.current = setInterval(() => {
      ticks++;
      if (ticks < maxTicks) {
        // Show random values during animation
        setDisplayDice(rollDice());
      } else {
        // Land on final value
        clearInterval(rollIntervalRef.current);
        rollIntervalRef.current = null;
        setDisplayDice(finalValue);
        setCurrentDice(finalValue);
        setIsRolling(false);
        if (onComplete) onComplete(finalValue);
      }
    }, 50 + ticks * 8); // Gradually slow down
  }, []);

  const handlePlayerMove = (colIndex) => {
    if (!isPlayerTurn || currentDice === null || gameOver) return;
    const available = getAvailableColumns(playerGrid);
    if (!available.includes(colIndex)) return;

    const newPlayerGrid = placeDice(playerGrid, colIndex, currentDice);
    const newOpponentGrid = removeMatchingDice(opponentGrid, colIndex, currentDice);
    
    setPlayerGrid(newPlayerGrid);
    setOpponentGrid(newOpponentGrid);
    setCurrentDice(null);
    setDisplayDice(null);
    
    if (!checkGameOver(newPlayerGrid, newOpponentGrid)) {
      setIsPlayerTurn(false);
    }
  };

  // AI turn
  useEffect(() => {
    if (isPlayerTurn || gameOver) return;

    const timer = setTimeout(() => {
      animateRoll((dice) => {
        setTimeout(() => {
          const available = getAvailableColumns(opponentGrid);
          if (available.length === 0) return;
          
          let bestCol = available[0];
          let bestScore = -Infinity;
          
          available.forEach(colIdx => {
            let score = 0;
            const col = opponentGrid[colIdx];
            score += col.filter(v => v === dice).length * 10;
            score += playerGrid[colIdx].filter(v => v === dice).length * dice * 5;
            if (score > bestScore) {
              bestScore = score;
              bestCol = colIdx;
            }
          });
          
          const newOpponentGrid = placeDice(opponentGrid, bestCol, dice);
          const newPlayerGrid = removeMatchingDice(playerGrid, bestCol, dice);
          
          setOpponentGrid(newOpponentGrid);
          setPlayerGrid(newPlayerGrid);
          setCurrentDice(null);
          setDisplayDice(null);
          
          if (!checkGameOver(newPlayerGrid, newOpponentGrid)) {
            setIsPlayerTurn(true);
          }
        }, 400);
      });
    }, 500);

    return () => clearTimeout(timer);
  }, [isPlayerTurn, gameOver, opponentGrid, playerGrid, placeDice, removeMatchingDice, checkGameOver, animateRoll]);

  // Cleanup interval on unmount
  useEffect(() => {
    return () => {
      if (rollIntervalRef.current) {
        clearInterval(rollIntervalRef.current);
      }
    };
  }, []);

  const handleRollDice = () => {
    if (!isPlayerTurn || currentDice !== null || gameOver || isRolling) return;
    animateRoll();
  };

  const resetGame = () => {
    setPlayerGrid(Array(3).fill(null).map(() => Array(3).fill(null)));
    setOpponentGrid(Array(3).fill(null).map(() => Array(3).fill(null)));
    setCurrentDice(null);
    setDisplayDice(null);
    setIsPlayerTurn(true);
    setGameOver(false);
    setWinner(null);
  };

  // Minimal dice
  const Dice = ({ value, size = 40, rolling = false }) => {
    const dots = {
      1: [[1,1]],
      2: [[0,2], [2,0]],
      3: [[0,2], [1,1], [2,0]],
      4: [[0,0], [0,2], [2,0], [2,2]],
      5: [[0,0], [0,2], [1,1], [2,0], [2,2]],
      6: [[0,0], [0,2], [1,0], [1,2], [2,0], [2,2]]
    };
    
    const dotSize = size * 0.15;
    
    return (
      <div style={{
        width: size,
        height: size,
        background: '#fff',
        borderRadius: 4,
        border: '1px solid #ccc',
        display: 'grid',
        gridTemplateColumns: 'repeat(3, 1fr)',
        gridTemplateRows: 'repeat(3, 1fr)',
        padding: size * 0.12,
        boxSizing: 'border-box',
        transition: rolling ? 'none' : 'transform 0.1s',
        transform: rolling ? `rotate(${(value || 1) * 30}deg)` : 'rotate(0deg)'
      }}>
        {[0,1,2].map(row => 
          [0,1,2].map(col => (
            <div key={`${row}-${col}`} style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center'
            }}>
              {value && dots[value]?.some(([r,c]) => r === row && c === col) && (
                <div style={{
                  width: dotSize,
                  height: dotSize,
                  borderRadius: '50%',
                  background: '#333'
                }} />
              )}
            </div>
          ))
        )}
      </div>
    );
  };

  // Grid component
  const Grid = ({ grid, isPlayer, onColumnClick }) => {
    const available = isPlayer && currentDice !== null ? getAvailableColumns(grid) : [];
    
    return (
      <div style={{ display: 'flex', gap: 8 }}>
        {grid.map((col, colIdx) => {
          const colScore = calculateColumnScore(col);
          const isClickable = available.includes(colIdx);
          
          const getVisualCell = (visualRow) => {
            if (isPlayer) {
              return col[visualRow];
            } else {
              return col[2 - visualRow];
            }
          };
          
          return (
            <div 
              key={colIdx} 
              style={{ 
                display: 'flex', 
                flexDirection: 'column', 
                alignItems: 'center',
                gap: 4
              }}
            >
              {!isPlayer && (
                <div style={{ fontSize: 14, fontWeight: 600, color: '#666', height: 20 }}>
                  {colScore > 0 ? colScore : ''}
                </div>
              )}
              
              <div
                onClick={() => isClickable && onColumnClick(colIdx)}
                style={{
                  display: 'flex',
                  flexDirection: 'column',
                  gap: 4,
                  padding: 6,
                  background: isClickable ? '#e8f5e9' : '#f5f5f5',
                  border: isClickable ? '2px solid #4caf50' : '2px solid #e0e0e0',
                  borderRadius: 6,
                  cursor: isClickable ? 'pointer' : 'default'
                }}
              >
                {[0, 1, 2].map((visualRow) => {
                  const cell = getVisualCell(visualRow);
                  return (
                    <div 
                      key={visualRow} 
                      style={{
                        width: 48,
                        height: 48,
                        background: cell ? 'transparent' : '#eee',
                        borderRadius: 4,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center'
                      }}
                    >
                      {cell && <Dice value={cell} size={40} />}
                    </div>
                  );
                })}
              </div>
              
              {isPlayer && (
                <div style={{ fontSize: 14, fontWeight: 600, color: '#666', height: 20 }}>
                  {colScore > 0 ? colScore : ''}
                </div>
              )}
            </div>
          );
        })}
      </div>
    );
  };

  const playerScore = calculateTotalScore(playerGrid);
  const opponentScore = calculateTotalScore(opponentGrid);

  return (
    <div style={{
      minHeight: '100vh',
      background: '#fafafa',
      padding: 24,
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      fontFamily: 'system-ui, -apple-system, sans-serif',
      color: '#333'
    }}>
      <h1 style={{ margin: '0 0 24px 0', fontSize: 24, fontWeight: 600 }}>
        Knucklebones
      </h1>

      {/* Opponent */}
      <div style={{ marginBottom: 8, textAlign: 'center' }}>
        <div style={{ fontSize: 14, marginBottom: 8, color: '#666' }}>
          Opponent: <strong>{opponentScore}</strong>
        </div>
        <Grid grid={opponentGrid} isPlayer={false} onColumnClick={() => {}} />
      </div>

      {/* Center area */}
      <div style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 24,
        margin: '16px 0',
        padding: 16,
        background: '#fff',
        border: '1px solid #e0e0e0',
        borderRadius: 8,
        minHeight: 80,
        minWidth: 240
      }}>
        {gameOver ? (
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontSize: 18, marginBottom: 12 }}>
              {winner === 'player' ? 'You win!' : 
               winner === 'opponent' ? 'Opponent wins!' : 'Draw!'}
            </div>
            <button
              onClick={resetGame}
              style={{
                padding: '8px 20px',
                fontSize: 14,
                background: '#333',
                color: '#fff',
                border: 'none',
                borderRadius: 4,
                cursor: 'pointer'
              }}
            >
              Play again
            </button>
          </div>
        ) : (
          <>
            <div style={{ fontSize: 13, color: '#888', minWidth: 80 }}>
              {isPlayerTurn ? 'Your turn' : 'Opponent...'}
            </div>
            
            {displayDice !== null ? (
              <div style={{ textAlign: 'center' }}>
                <Dice value={displayDice} size={48} rolling={isRolling} />
                {isPlayerTurn && !isRolling && (
                  <div style={{ fontSize: 11, marginTop: 6, color: '#4caf50' }}>
                    Select column
                  </div>
                )}
              </div>
            ) : isPlayerTurn ? (
              <button
                onClick={handleRollDice}
                disabled={isRolling}
                style={{
                  padding: '10px 24px',
                  fontSize: 14,
                  background: isRolling ? '#ccc' : '#333',
                  color: '#fff',
                  border: 'none',
                  borderRadius: 4,
                  cursor: isRolling ? 'wait' : 'pointer'
                }}
              >
                {isRolling ? '...' : 'Roll'}
              </button>
            ) : (
              <div style={{ width: 48, height: 48 }} />
            )}
            
            <div style={{ minWidth: 80 }} />
          </>
        )}
      </div>

      {/* Player */}
      <div style={{ marginTop: 8, textAlign: 'center' }}>
        <Grid 
          grid={playerGrid} 
          isPlayer={true} 
          onColumnClick={handlePlayerMove} 
        />
        <div style={{ fontSize: 14, marginTop: 8, color: '#666' }}>
          You: <strong>{playerScore}</strong>
        </div>
      </div>

      {/* Rules */}
      <div style={{
        marginTop: 32,
        padding: 16,
        background: '#fff',
        border: '1px solid #e0e0e0',
        borderRadius: 6,
        fontSize: 13,
        color: '#666',
        maxWidth: 320,
        lineHeight: 1.5
      }}>
        <strong>Rules:</strong> Place dice in columns. Matching dice multiply. 
        Your dice remove matching opponent dice in the same column.
      </div>
    </div>
  );
}

export default Knucklebones;
